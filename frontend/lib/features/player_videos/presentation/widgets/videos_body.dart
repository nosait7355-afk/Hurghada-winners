import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video_service.dart';
import 'package:hurghada_winners/features/player_videos/presentation/providers/player_video_providers.dart';
import 'package:hurghada_winners/features/player_videos/presentation/widgets/video_card.dart';
import 'package:hurghada_winners/features/player_videos/presentation/widgets/video_comments_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// رسالة الخطأ الحقيقية من الخادم إن وُجدت، وإلا نصّ عام.
String videoErrorMessage(Object? error, {required String fallback}) {
  if (error is AppException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return fallback;
}

/// الإجراءات المشتركة بين جهة الإدارة وجهة اللاعب (إعجاب + تعليقات).
/// الفرق الوحيد هو [service] المستخدمة و[isAcademy] لصلاحية حذف التعليقات.
class VideoActions {
  final PlayerVideoService service;
  final VideosNotifier notifier;
  final bool isAcademy;

  const VideoActions({
    required this.service,
    required this.notifier,
    required this.isAcademy,
  });

  Future<void> toggleLike(BuildContext context, PlayerVideo video) async {
    final messenger = ScaffoldMessenger.of(context);
    // تحديث متفائل ليستجيب الزر فوراً، ثم نصحّحه بردّ الخادم.
    notifier.replace(video.copyWith(
      likedByMe: !video.likedByMe,
      likesCount: video.likesCount + (video.likedByMe ? -1 : 1),
    ));
    try {
      final updated = await service.setLike(video.id, !video.likedByMe);
      notifier.replace(updated);
    } catch (e) {
      notifier.replace(video); // تراجع عن التحديث المتفائل
      messenger.showSnackBar(SnackBar(
        content: Text(videoErrorMessage(e, fallback: 'تعذّر تسجيل الإعجاب')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> openComments(BuildContext context, PlayerVideo video) {
    return showVideoCommentsSheet(
      context: context,
      service: service,
      video: video,
      isAcademy: isAcademy,
      onCountChanged: (delta) => notifier.bumpComments(video.id, delta),
    );
  }
}

/// جسم قائمة الفيديوهات — حالات التحميل/الخطأ/الفراغ + سحب للتحديث +
/// تحميل كسول. مشترك بين الشاشتين.
class VideosBody extends StatefulWidget {
  final VideosState state;
  final VideoActions actions;
  final String emptyText;

  /// إجراءات الإدارة — null في جهة اللاعب.
  final void Function(PlayerVideo)? onEdit;
  final void Function(PlayerVideo)? onDelete;

  const VideosBody({
    super.key,
    required this.state,
    required this.actions,
    required this.emptyText,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<VideosBody> createState() => _VideosBodyState();
}

class _VideosBodyState extends State<VideosBody> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      widget.actions.notifier.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 44),
              SizedBox(height: 12.h),
              Text(
                videoErrorMessage(state.error, fallback: 'تعذّر تحميل الفيديوهات'),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: widget.actions.notifier.refresh,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.actions.notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120.h),
            Icon(Icons.video_library_outlined, size: 52.sp, color: AppColors.grey400),
            SizedBox(height: 12.h),
            Text(
              widget.emptyText,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey500, fontSize: 15.sp),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.actions.notifier.refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12.r, 12.r, 12.r, 90.r),
        itemCount: state.items.length + (state.loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= state.items.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          final video = state.items[i];
          return VideoCard(
            video: video,
            onToggleLike: () => widget.actions.toggleLike(context, video),
            onOpenComments: () => widget.actions.openComments(context, video),
            onEdit: widget.onEdit == null ? null : () => widget.onEdit!(video),
            onDelete: widget.onDelete == null ? null : () => widget.onDelete!(video),
          );
        },
      ),
    );
  }
}
