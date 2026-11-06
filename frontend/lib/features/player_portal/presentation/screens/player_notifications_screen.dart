import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/widgets/confirm_delete_dialog.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/player_portal/data/player_api_service.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:hurghada_winners/features/player_portal/presentation/screens/player_renewal_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// إشعارات اللاعب.
class PlayerNotificationsScreen extends ConsumerWidget {
  const PlayerNotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'NEW_MESSAGE':
        return Icons.chat_bubble_outline;
      case 'ATTENDANCE_PRESENT':
        return Icons.how_to_reg_outlined;
      case 'EVALUATION_ADDED':
        return Icons.star_outline;
      case 'SUBSCRIPTION_RENEWED':
        return Icons.card_membership_outlined;
      case 'RENEWAL_REQUEST_REVIEWED':
        return Icons.receipt_long_outlined;
      case 'SUBSCRIPTION_EXPIRING':
        return Icons.timer_outlined;
      case 'PLAYER_VIDEO_ADDED':
        return Icons.play_circle_outline;
      case 'PLAYER_VIDEO_COMMENT':
        return Icons.mode_comment_outlined;
      case 'ABSENCE_ALERT':
        return Icons.event_busy_outlined;
      case 'PLAYER_PHOTO_UPDATED':
        return Icons.account_circle_outlined;
      case 'ALBUM_PHOTO_ADDED':
        return Icons.photo_library_outlined;
      case 'OFFER_ADDED':
        return Icons.local_offer_outlined;
      case 'KIT_BOOKING_APPROVED':
      case 'KIT_BOOKING_REJECTED':
        return Icons.checkroom_outlined;
      case 'TOURNAMENT_SCHEDULED':
      case 'TOURNAMENT_RESULT':
        return Icons.emoji_events_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// وجهة الإشعار عند الضغط (null = لا وجهة).
  void _open(BuildContext context, String type) {
    switch (type) {
      case 'SUBSCRIPTION_EXPIRING':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlayerRenewalRequestScreen()));
      case 'ABSENCE_ALERT':
      case 'NEW_MESSAGE':
        context.push(AppRoutes.playerChat);
      case 'ALBUM_PHOTO_ADDED':
        context.push(AppRoutes.playerAlbum);
      case 'PLAYER_VIDEO_ADDED':
      case 'PLAYER_VIDEO_COMMENT':
        context.push(AppRoutes.playerMyVideos);
      case 'OFFER_ADDED':
        context.push(AppRoutes.playerOffers);
      case 'KIT_BOOKING_APPROVED':
      case 'KIT_BOOKING_REJECTED':
        context.push(AppRoutes.playerTeamKit);
      case 'TOURNAMENT_SCHEDULED':
      case 'TOURNAMENT_RESULT':
        context.push(AppRoutes.playerTournaments);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            tooltip: 'تعليم الكل كمقروء',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await sl<PlayerApiService>().markAllNotificationsRead();
              ref.invalidate(playerNotificationsProvider);
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(playerNotificationsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ),
        data: (data) {
          final items = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
          if (items.isEmpty) {
            return Center(
              child: Text('لا توجد إشعارات',
                  style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(playerNotificationsProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(12.r),
              itemCount: items.length,
              separatorBuilder: (_, __) => Gap(8.h),
              itemBuilder: (context, i) {
                final n = items[i];
                final isRead = n['isRead'] == true;
                final createdAt = DateTime.tryParse(n['createdAt'] as String? ?? '');
                return ListTile(
                  tileColor: isRead ? AppColors.white : AppColors.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  leading: Icon(_iconFor(n['type'] as String? ?? ''), color: AppColors.primary),
                  title: Text(n['title'] as String? ?? '',
                      style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w800)),
                  subtitle: Text(n['body'] as String? ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (createdAt != null)
                        Text(DateFormat('MM/dd HH:mm').format(createdAt),
                            style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
                      DeleteIconButton(
                        size: 18.sp,
                        onPressed: () async {
                          final ok = await confirmDelete(context,
                              title: 'حذف الإشعار',
                              message: 'حذف "${n['title'] ?? ''}"؟');
                          if (!ok) return;
                          try {
                            await sl<PlayerApiService>()
                                .deleteNotification(n['_id'] as String);
                          } catch (_) {}
                          ref
                            ..invalidate(playerNotificationsProvider)
                            ..invalidate(playerDashboardProvider);
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!isRead) {
                      await sl<PlayerApiService>()
                          .markNotificationRead(n['_id'] as String);
                      ref
                        ..invalidate(playerNotificationsProvider)
                        ..invalidate(playerDashboardProvider);
                    }
                    if (context.mounted) _open(context, n['type'] as String? ?? '');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
