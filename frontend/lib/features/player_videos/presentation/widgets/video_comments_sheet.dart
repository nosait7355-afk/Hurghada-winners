import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// شيت التعليقات — مشترك بين الإدارة واللاعب. الفرق الوحيد هو [service]
/// (مسارات /player-videos أو /player/videos) و[isAcademy] الذي يحدّد من
/// يستطيع حذف أي تعليق: الإدارة تحذف الكل، واللاعب تعليقه فقط.
///
/// [onCountChanged] يُستدعى بـ +1 أو -1 لحظة كل إضافة/حذف، لا عند الإغلاق —
/// فيبقى عدّاد البطاقة صحيحاً حتى لو أُغلقت الورقة بالسحب لا بزر الإغلاق.
Future<void> showVideoCommentsSheet({
  required BuildContext context,
  required PlayerVideoService service,
  required PlayerVideo video,
  required bool isAcademy,
  required void Function(int delta) onCountChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CommentsSheet(
      service: service,
      video: video,
      isAcademy: isAcademy,
      onCountChanged: onCountChanged,
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  final PlayerVideoService service;
  final PlayerVideo video;
  final bool isAcademy;
  final void Function(int delta) onCountChanged;

  const _CommentsSheet({
    required this.service,
    required this.video,
    required this.isAcademy,
    required this.onCountChanged,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _textCtrl = TextEditingController();

  /// controller الخاص بـ DraggableScrollableSheet — نحتفظ به لننزل لآخر
  /// تعليق بعد الإرسال. تملكه الورقة، فلا نتخلّص منه هنا.
  ScrollController? _listScroll;

  List<VideoComment> _comments = const [];
  bool _loading = true;
  bool _sending = false;
  Object? _error;


  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.service.getComments(widget.video.id);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String _msg(Object? e, String fallback) =>
      (e is AppException && e.message.trim().isNotEmpty) ? e.message : fallback;

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await widget.service.addComment(widget.video.id, text);
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, comment];
        _sending = false;
      });
      widget.onCountChanged(1);
      _textCtrl.clear();
      // ننزل لآخر تعليق بعد أن يُبنى الإطار.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sc = _listScroll;
        if (sc != null && sc.hasClients) {
          sc.animateTo(
            sc.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_msg(e, 'تعذّر إرسال التعليق')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _delete(VideoComment comment) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: const Text('هل تريد حذف هذا التعليق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.deleteComment(widget.video.id, comment.id);
      if (!mounted) return;
      setState(() {
        _comments = _comments.where((c) => c.id != comment.id).toList();
      });
      widget.onCountChanged(-1);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(_msg(e, 'تعذّر حذف التعليق')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  /// الإدارة تحذف أي تعليق؛ اللاعب يحذف تعليقاته هو فقط (نفس قاعدة الخادم).
  bool _canDelete(VideoComment c) => widget.isAcademy || !c.isFromAcademy;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, sheetScroll) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Icon(Icons.mode_comment_outlined, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text('التعليقات',
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _list(sheetScroll)),
                const Divider(height: 1),
                _composer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _list(ScrollController sheetScroll) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_msg(_error, 'تعذّر تحميل التعليقات')),
            SizedBox(height: 10.h),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mode_comment_outlined, size: 40.sp, color: AppColors.grey400),
            SizedBox(height: 10.h),
            Text('لا توجد تعليقات بعد — كن أول من يعلّق',
                style: TextStyle(color: AppColors.grey500, fontSize: 14.sp)),
          ],
        ),
      );
    }

    // نفس الـ controller الذي تعطيه الورقة، وإلا تعطّل سحبها لأعلى/أسفل.
    _listScroll = sheetScroll;
    return ListView.separated(
      controller: sheetScroll,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) => _CommentTile(
        comment: _comments[i],
        onDelete: _canDelete(_comments[i]) ? () => _delete(_comments[i]) : null,
      ),
    );
  }

  Widget _composer() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              maxLength: 1000,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'اكتب تعليقاً…',
                counterText: '',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton.filled(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final VideoComment comment;
  final VoidCallback? onDelete;

  const _CommentTile({required this.comment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAcademy = comment.isFromAcademy;
    final accent = isAcademy ? AppColors.primary : AppColors.secondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16.r,
          backgroundColor: accent.withValues(alpha: 0.12),
          child: Icon(
            isAcademy ? Icons.sports : Icons.person_outline,
            size: 17.sp,
            color: accent,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorName.isEmpty
                            ? (isAcademy ? 'الأكاديمية' : 'اللاعب')
                            : comment.authorName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: accent),
                      ),
                    ),
                    if (comment.createdAt != null) ...[
                      SizedBox(width: 6.w),
                      Text(
                        DateFormat('yyyy/MM/dd – HH:mm').format(comment.createdAt!),
                        style: TextStyle(fontSize: 10.sp, color: AppColors.grey500),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(comment.text, style: TextStyle(fontSize: 14.sp)),
              ],
            ),
          ),
        ),
        if (onDelete != null)
          IconButton(
            tooltip: 'حذف',
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: 18.sp, color: AppColors.grey500),
          ),
      ],
    );
  }
}
