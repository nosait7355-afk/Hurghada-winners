import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';
import 'package:hurghada_winners/features/player_videos/presentation/screens/video_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// بطاقة فيديو مشتركة بين شاشة الإدارة وشاشة اللاعب.
/// الضغط يفتح مشغّل يوتيوب داخل التطبيق، أو التطبيق الخارجي لروابط درايف
/// وعلى ويندوز — راجع [openPlayerVideo].
class VideoCard extends StatelessWidget {
  final PlayerVideo video;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;

  /// إجراءات الإدارة — تُمرَّر null في جهة اللاعب فتختفي القائمة.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VideoCard({
    super.key,
    required this.video,
    required this.onToggleLike,
    required this.onOpenComments,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final manage = onEdit != null || onDelete != null;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── المصغّر ──
          InkWell(
            onTap: () => openPlayerVideo(context, video),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (video.thumbnailUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.grey200),
                      errorWidget: (_, __, ___) => const _ThumbFallback(),
                    )
                  else
                    const _ThumbFallback(),
                  if (!video.isImage)
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 34.sp),
                    ),
                  ),
                  if (manage)
                    PositionedDirectional(
                      top: 4.r,
                      end: 4.r,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              color: Colors.white, size: 20.sp),
                          onSelected: (v) {
                            if (v == 'edit') onEdit?.call();
                            if (v == 'delete') onDelete?.call();
                          },
                          itemBuilder: (_) => [
                            if (onEdit != null)
                              const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف',
                                    style: TextStyle(color: AppColors.error)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    bottom: 6.r,
                    start: 6.r,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 3.r),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        video.isImage
                            ? 'صورة'
                            : (video.isYoutube ? 'YouTube' : 'Google Drive'),
                        style: TextStyle(color: Colors.white, fontSize: 10.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── النص ──
          Padding(
            padding: EdgeInsets.fromLTRB(12.r, 10.r, 12.r, 4.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                ),
                if (video.description.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    video.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.sp, color: AppColors.grey600),
                  ),
                ],
              ],
            ),
          ),

          // ── التفاعل ──
          Padding(
            padding: EdgeInsets.fromLTRB(4.r, 0, 4.r, 4.r),
            child: Row(
              children: [
                _ActionButton(
                  icon: video.likedByMe ? Icons.favorite : Icons.favorite_border,
                  color: video.likedByMe ? AppColors.error : AppColors.grey600,
                  label: '${video.likesCount}',
                  onTap: onToggleLike,
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  color: AppColors.grey600,
                  label: '${video.commentsCount}',
                  onTap: onOpenComments,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => openPlayerVideo(context, video),
                  icon: Icon(Icons.play_circle_outline, size: 18.sp),
                  label: Text('مشاهدة', style: TextStyle(fontSize: 13.sp)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: Center(
        child: Icon(Icons.movie_outlined,
            color: AppColors.white.withValues(alpha: 0.7), size: 40.sp),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18.sp, color: color),
      label: Text(label, style: TextStyle(fontSize: 13.sp, color: color)),
    );
  }
}
