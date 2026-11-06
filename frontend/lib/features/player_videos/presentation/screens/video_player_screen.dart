import 'dart:async';

import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/widgets/full_screen_image_viewer.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// معرّف يوتيوب الصالح للفيديو، أو null إن لم يكن يوتيوب. نعتمد videoKey
/// القادم من الخادم، ونشتقّه من الرابط كخطة بديلة لأي سجل قديم بلا الحقل.
String? youtubeIdOf(PlayerVideo video) {
  if (!video.isYoutube) return null;
  if (video.videoKey.isNotEmpty) return video.videoKey;
  return YoutubePlayerController.convertUrlToId(video.url);
}

/// هل نشغّله داخل التطبيق؟ يوتيوب على الموبايل والويب: المشغّل يعتمد على
/// webview_flutter الذي لا نسخة له لويندوز، وروابط Google Drive تُفتح خارجياً
/// دائماً. نستخدم defaultTargetPlatform لا Platform لأن dart:io غير متاحة
/// على الويب.
bool _playsInApp(PlayerVideo video) {
  if (youtubeIdOf(video) == null) return false;
  return kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// نقطة الدخول الوحيدة لتشغيل فيديو: مشغّل داخلي حيث يمكن، وإلا تطبيق خارجي.
Future<void> openPlayerVideo(BuildContext context, PlayerVideo video) async {
  if (video.isImage) {
    await showFullScreenImage(context, video.url);
    return;
  }
  if (_playsInApp(video)) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(
          video: video,
          videoId: youtubeIdOf(video)!,
        ),
      ),
    );
    return;
  }
  await openVideoExternally(context, video.url);
}

/// فتح الرابط في تطبيق الجهاز (يوتيوب/درايف/المتصفح).
Future<void> openVideoExternally(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  bool ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger.showSnackBar(const SnackBar(content: Text('تعذّر فتح الفيديو')));
  }
}

/// شاشة تشغيل فيديو يوتيوب داخل التطبيق عبر مشغّل IFrame الرسمي.
/// الإعجاب والتعليقات تبقى على بطاقة الفيديو في القائمة.
class VideoPlayerScreen extends StatefulWidget {
  final PlayerVideo video;
  final String videoId;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.videoId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubePlayerValue>? _sub;

  /// آخر خطأ أبلغ عنه المشغّل — نستبدل به مساحة الفيديو مع زر فتح خارجي،
  /// لأن أشهر سبب (منع التضمين) لا حلّ له داخل التطبيق.
  YoutubeError _error = YoutubeError.none;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        interfaceLanguage: 'ar',
        captionLanguage: 'ar',
        // لا نقترح فيديوهات من قنوات أخرى بعد الانتهاء.
        strictRelatedVideos: true,
      ),
    );
    _sub = _controller.stream.listen((value) {
      if (!mounted || value.error == _error) return;
      setState(() => _error = value.error);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }

  String get _errorText => switch (_error) {
        YoutubeError.notEmbeddable ||
        YoutubeError.sameAsNotEmbeddable ||
        YoutubeError.sameAsNotEmbeddable2 =>
          'صاحب الفيديو لا يسمح بتشغيله داخل التطبيقات',
        YoutubeError.videoNotFound || YoutubeError.cannotFindVideo =>
          'الفيديو لم يعد متاحاً — رُبما حُذف أو أصبح خاصاً',
        YoutubeError.invalidParam => 'رابط الفيديو غير صالح',
        _ => 'تعذّر تشغيل الفيديو',
      };

  @override
  Widget build(BuildContext context) {
    final video = widget.video;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 24.h),
        children: [
          Container(
            color: AppColors.black,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _error == YoutubeError.none
                  ? YoutubePlayer(controller: _controller)
                  : _PlayerError(
                      message: _errorText,
                      onOpenExternally: () =>
                          openVideoExternally(context, video.url),
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.r, 14.r, 16.r, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style:
                      TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
                ),
                if (video.createdByName.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'أضافه ${video.createdByName}',
                    style:
                        TextStyle(fontSize: 12.sp, color: AppColors.grey500),
                  ),
                ],
                if (video.description.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Text(
                    video.description,
                    style:
                        TextStyle(fontSize: 14.sp, color: AppColors.grey700),
                  ),
                ],
                SizedBox(height: 8.h),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => openVideoExternally(context, video.url),
                    icon: Icon(Icons.open_in_new, size: 16.sp),
                    label: Text(
                      'فتح في يوتيوب',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerError extends StatelessWidget {
  final String message;
  final VoidCallback onOpenExternally;

  const _PlayerError({required this.message, required this.onOpenExternally});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.grey400, size: 34.sp),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white, fontSize: 13.sp),
          ),
          SizedBox(height: 6.h),
          TextButton.icon(
            onPressed: onOpenExternally,
            icon: Icon(Icons.open_in_new, size: 16.sp, color: AppColors.white),
            label: Text(
              'فتح في يوتيوب',
              style: TextStyle(color: AppColors.white, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}
