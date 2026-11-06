import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/notification/domain/entities/notification_entity.dart';
import 'package:hurghada_winners/features/notification/presentation/providers/notification_provider.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_detail_screen.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        title: Text(
          'الإشعارات',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          notifAsync.whenOrNull(
            data: (list) => list.isNotEmpty
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.white),
                    onSelected: (value) async {
                      if (value == 'mark_all') {
                        await notifier.markAllAsRead();
                      } else if (value == 'delete_all') {
                        final confirmed = await _confirmDeleteAll(context);
                        if (confirmed == true) await notifier.deleteAll();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'mark_all',
                        child: Row(
                          children: [
                            Icon(Icons.done_all, size: 20),
                            SizedBox(width: 8),
                            Text('تحديد الكل كمقروء'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_outlined,
                                size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف جميع الإشعارات',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
              Gap(12.h),
              const Text('تعذر تحميل الإشعارات'),
              Gap(12.h),
              TextButton(
                onPressed: () => notifier.refresh(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => notifier.refresh(),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: list.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 72.w,
                color: AppColors.grey200,
              ),
              itemBuilder: (context, index) {
                final notif = list[index];
                return _NotificationTile(
                  notification: notif,
                  onTap: () => _handleTap(context, ref, notifier, notif),
                  onDelete: () => notifier.deleteNotification(notif.id),
                  // يوم عيد الميلاد: زر معايدة مباشر برسالة جاهزة.
                  onCongratulate: notif.type == NotificationType.birthday &&
                          notif.id.startsWith('birthday_') &&
                          !notif.id.startsWith('birthday_tomorrow_')
                      ? () {
                          notifier.deleteNotification(notif.id);
                          _sendWhatsApp(context, notif);
                        }
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // الضغط على الإشعار:
  //  • طلب انضمام → تفاصيل الطلب.
  //  • عيد ميلاد / اشتراك → اختياران: صفحة اللاعب أو واتساب برسالة جاهزة.
  // بعد تنفيذ الاختيار يختفي الإشعار ولا يظهر مرة أخرى (إغلاق الاختيارات
  // بلا اختيار يُبقيه).
  Future<void> _handleTap(BuildContext context, WidgetRef ref,
      NotificationNotifier notifier, NotificationEntity n) async {
    notifier.markAsRead(n.id);

    if (n.type == NotificationType.joinRequest) {
      // إشعارات السوبر أدمن تجمع كل الفروع، وأكاديميته null — فنعتمد أكاديمية
      // الإشعار نفسه، ونرجع لأكاديمية المستخدم لباقي الأدوار.
      final academyId = n.academyId ??
          ref.read(authStateProvider).valueOrNull?.user?.academyId;
      if (academyId != null && n.playerId != null) {
        notifier.deleteNotification(n.id);
        context.push(
          AppRoutes.joinRequestDetail
              .replaceFirst(':id', academyId)
              .replaceFirst(':requestId', n.playerId!),
        );
      }
      return;
    }

    if (n.playerId == null) return;
    final isBirthday = n.type == NotificationType.birthday;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Text(n.playerName ?? n.title,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.primary),
              title: const Text('الدخول على صفحة اللاعب'),
              onTap: () => Navigator.pop(ctx, 'page'),
            ),
            ListTile(
              leading: Icon(isBirthday ? Icons.cake_outlined : Icons.chat_outlined,
                  color: const Color(0xFF25D366)),
              title: Text(isBirthday
                  ? 'معايدة على واتساب (رسالة جاهزة)'
                  : 'مراسلة على واتساب (رسالة جاهزة)'),
              onTap: () => Navigator.pop(ctx, 'whatsapp'),
            ),
            Gap(8.h),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    notifier.deleteNotification(n.id);
    if (choice == 'page') {
      _openPlayer(context, n);
    } else {
      await _sendWhatsApp(context, n);
    }
  }

  static void _openPlayer(BuildContext context, NotificationEntity n) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerDetailScreen(
        playerId: n.playerId!,
        academyId: n.academyId ?? '',
      ),
    ));
  }

  static Future<void> _sendWhatsApp(
      BuildContext context, NotificationEntity n) async {
    final phone = n.parentPhone?.trim() ?? '';
    final messenger = ScaffoldMessenger.of(context);
    if (phone.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('لا يوجد رقم لولي الأمر'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    final academyName = n.academyName ?? 'الأكاديمية';
    final message = switch (n.type) {
      NotificationType.birthday => WhatsAppUtils.birthdayTemplate(
          academyName: academyName,
          playerName: n.playerName ?? '',
        ),
      NotificationType.absence => WhatsAppUtils.absenceTemplate(
          academyName: academyName,
          playerName: n.playerName ?? '',
          count: n.absentCount ?? 2,
        ),
      _ => WhatsAppUtils.renewalReminderTemplate(
          academyName: academyName,
          playerName: n.playerName ?? '',
          endDate: n.subscriptionEndDate,
        ),
    };
    final ok = await WhatsAppUtils.open(phone, message: message);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر فتح واتساب'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<bool?> _confirmDeleteAll(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف جميع الإشعارات'),
        content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80.sp,
            color: AppColors.grey300,
          ),
          Gap(16.h),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
            ),
          ),
          Gap(8.h),
          Text(
            'ستظهر هنا أعياد الميلاد وتذكير الاشتراكات\nوطلبات الانضمام والغياب المتكرر',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Tile ───────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onCongratulate;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
    this.onCongratulate,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: AppColors.error,
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsets.only(right: 20.w),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead ? null : AppColors.primaryContainer.withValues(alpha: 0.3),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotifIcon(type: notification.type),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppColors.grey900,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    Gap(4.h),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.grey600,
                        height: 1.4,
                      ),
                    ),
                    Gap(6.h),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.grey400,
                      ),
                    ),
                    if (onCongratulate != null) ...[
                      Gap(8.h),
                      ElevatedButton.icon(
                        onPressed: onCongratulate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: AppColors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.cake_outlined, size: 18),
                        label: const Text('معايدة'),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16.sp, color: AppColors.grey400),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.w),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return 'اليوم ${DateFormat('HH:mm').format(dt)}';
    if (day == today.subtract(const Duration(days: 1))) return 'أمس';
    return DateFormat('dd/MM/yyyy', 'ar').format(dt);
  }
}

class _NotifIcon extends StatelessWidget {
  final NotificationType type;
  const _NotifIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.birthday => (Icons.cake_outlined, AppColors.primary),
      NotificationType.subscriptionExpiring =>
        (Icons.warning_amber_outlined, AppColors.warning),
      NotificationType.subscriptionExpired =>
        (Icons.cancel_outlined, AppColors.error),
      NotificationType.joinRequest =>
        (Icons.person_add_alt_1_outlined, AppColors.warning),
      NotificationType.absence =>
        (Icons.event_busy_outlined, AppColors.error),
      NotificationType.system =>
        (Icons.info_outline, AppColors.secondary),
    };

    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22.sp),
    );
  }
}

// ─── Bell Icon Widget (استخدامها في AppBar) ─────────────────────────────────

class NotificationBellIcon extends ConsumerWidget {
  final VoidCallback onTap;
  const NotificationBellIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return IconButton(
      onPressed: onTap,
      tooltip: 'الإشعارات',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(
          unread > 9 ? '9+' : '$unread',
          style: TextStyle(fontSize: 10.sp, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

// ─── Recent Notifications Widget (لـ Dashboard) ─────────────────────────────

class RecentNotificationsWidget extends ConsumerWidget {
  final VoidCallback onViewAll;
  const RecentNotificationsWidget({super.key, required this.onViewAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return notifAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        final recent = list.take(3).toList();
        final unreadCount = list.where((n) => !n.isRead).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'آخر الإشعارات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      Gap(8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Gap(8.h),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < recent.length; i++) ...[
                    _MiniNotifTile(notification: recent[i]),
                    if (i < recent.length - 1)
                      Divider(
                        height: 1,
                        indent: 56.w,
                        color: AppColors.grey100,
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniNotifTile extends StatelessWidget {
  final NotificationEntity notification;
  const _MiniNotifTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notification.type) {
      NotificationType.birthday => (Icons.cake_outlined, AppColors.primary),
      NotificationType.subscriptionExpiring =>
        (Icons.warning_amber_outlined, AppColors.warning),
      NotificationType.subscriptionExpired =>
        (Icons.cancel_outlined, AppColors.error),
      NotificationType.joinRequest =>
        (Icons.person_add_alt_1_outlined, AppColors.warning),
      NotificationType.absence => (Icons.event_busy_outlined, AppColors.error),
      NotificationType.system => (Icons.info_outline, AppColors.secondary),
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: notification.isRead
                        ? FontWeight.w500
                        : FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(2.h),
                Text(
                  notification.body.replaceAll('\n', ' '),
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 7.w,
              height: 7.w,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
