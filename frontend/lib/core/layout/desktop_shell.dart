// Ported from the Windows desktop project (G:\HolandaAcademyDesktop\frontend
// \lib\core\layout\desktop_shell.dart) so Desktop Web matches the Windows app
// pixel-for-pixel. Web-only: never imported by anything Android touches.
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/core/utils/privacy_launcher.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/chat/presentation/providers/chat_providers.dart';
import 'package:hurghada_winners/features/dashboard/presentation/providers/selected_academy_provider.dart';
import 'package:hurghada_winners/features/notification/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Sidebar width — matches the Windows reference exactly.
const double kSidebarWidth = 240.0;

// ─── DesktopShell ─────────────────────────────────────────────────────────────

class DesktopShell extends ConsumerWidget {
  final String location;
  final Widget child;

  const DesktopShell({super.key, required this.location, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final user = authState?.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AppSidebar(
            location: location,
            user: user,
            onLogout: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          Container(width: 1, color: AppColors.grey200),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Shared sidebar (also used by TabletShell) ───────────────────────────────

class AppSidebar extends ConsumerWidget {
  final String location;
  final UserEntity? user;
  final VoidCallback onLogout;

  const AppSidebar({
    super.key,
    required this.location,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final isAcademyAdmin = user?.isAcademyAdmin ?? false;
    final academyId = user?.academyId;
    // أكاديمية super_admin التي يتصرف كها (null إن لم يختر واحدة).
    final actingAcademyId = ref.watch(effectiveAcademyIdProvider);
    // عدّاد الرسائل مستقل عن الإشعارات، ولا يظهر إلا لمدير الأكاديمية
    // (المحادثات بين الأكاديمية ولاعبيها).
    final messagesUnread =
        isAcademyAdmin ? ref.watch(academyMessagesUnreadProvider) : 0;

    final academyName = academyId != null
        ? (ref.watch(academyByIdProvider(academyId)).valueOrNull?.name ??
            AppStrings.appName)
        : AppStrings.appName;

    final navItems =
        _buildNavItems(isSuperAdmin, isAcademyAdmin, academyId, actingAcademyId);

    return Container(
      width: kSidebarWidth,
      decoration: const BoxDecoration(color: AppColors.secondary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarLogoWithBell(
            academyName: academyName,
            unreadCount: unreadCount,
            messagesUnread: messagesUnread,
            showMessages: isAcademyAdmin,
            onBellTap: () => context.go(AppRoutes.notifications),
            onMessagesTap: () => context.go(AppRoutes.academyChat),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: navItems.length,
              itemBuilder: (_, i) {
                final item = navItems[i];
                if (item is _NavDivider) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: AppColors.white.withValues(alpha: 0.1),
                      height: 1,
                    ),
                  );
                }
                if (item is _NavItem) {
                  final isActive = _isActive(location, item.route);
                  return _SidebarNavTile(
                    item: item,
                    isActive: isActive,
                    onTap: () => context.go(item.route),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          _SidebarUserFooter(user: user, onLogout: onLogout),
        ],
      ),
    );
  }

  bool _isActive(String location, String route) {
    if (route == AppRoutes.home) {
      return location == AppRoutes.home || location == AppRoutes.dashboard;
    }
    if (route == AppRoutes.academyList) {
      return location.startsWith('/academies') &&
          !location.contains('/players') &&
          !location.contains('/users');
    }
    if (route.contains('/players')) return location.contains('/players');
    if (route == AppRoutes.reports) return location.startsWith('/reports');
    return location.startsWith(route);
  }

  List<Object> _buildNavItems(
    bool isSuperAdmin,
    bool isAcademyAdmin,
    String? academyId,
    String? actingAcademyId,
  ) {
    if (user?.isAdmin == true) {
      return [
        if (academyId != null) ...[
          _NavItem(
            icon: Icons.sports_tennis_outlined,
            activeIcon: Icons.sports_tennis,
            label: AppStrings.players,
            route: AppRoutes.playersList.replaceFirst(':id', academyId),
          ),
          _NavItem(
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups,
            label: 'المجموعات',
            route: AppRoutes.groupsList.replaceFirst(':id', academyId),
          ),
        ],
        _NavItem(
          icon: Icons.manage_accounts_outlined,
          activeIcon: Icons.manage_accounts,
          label: 'إعدادات الحساب',
          route: AppRoutes.accountSettings,
        ),
      ];
    }

    // الحسابات الإدارية المحدودة لا ترى لوحة الإحصائيات ولا التقارير.
    final canViewReports = user?.canViewReports != false;

    return [
      if ((isSuperAdmin || isAcademyAdmin) && canViewReports)
        _NavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          label: AppStrings.dashboard,
          route: AppRoutes.home,
        ),
      if (isSuperAdmin)
        _NavItem(
          icon: Icons.school_outlined,
          activeIcon: Icons.school,
          label: AppStrings.academies,
          route: AppRoutes.academyList,
        ),
      if (isAcademyAdmin && academyId != null) ...[
        _NavItem(
          icon: Icons.sports_tennis_outlined,
          activeIcon: Icons.sports_tennis,
          label: AppStrings.players,
          route: AppRoutes.playersList.replaceFirst(':id', academyId),
        ),
        _NavItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: AppStrings.users,
          route: AppRoutes.academyUsers.replaceFirst(':id', academyId),
        ),
        _NavItem(
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups,
          label: 'المجموعات',
          route: AppRoutes.groupsList.replaceFirst(':id', academyId),
        ),
        _NavItem(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          label: 'المحادثات',
          route: AppRoutes.academyChat,
        ),
        _NavItem(
          icon: Icons.photo_library_outlined,
          activeIcon: Icons.photo_library,
          label: 'ألبوم الأكاديمية',
          route: AppRoutes.academyAlbum,
        ),
        _NavItem(
          icon: Icons.badge_outlined,
          activeIcon: Icons.badge,
          label: 'الإدارة والموظفين',
          route: AppRoutes.staffList.replaceFirst(':id', academyId),
        ),
        if (canViewReports) ...[
          _NavItem(
            icon: Icons.payments_outlined,
            activeIcon: Icons.payments,
            label: 'الرواتب',
            route: AppRoutes.payrollList.replaceFirst(':id', academyId),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: 'المصروفات',
            route: AppRoutes.expensesList.replaceFirst(':id', academyId),
          ),
        ],
      ],
      if (isSuperAdmin && actingAcademyId != null) ...[
        _NavItem(
          icon: Icons.badge_outlined,
          activeIcon: Icons.badge,
          label: 'الإدارة والموظفين',
          route: AppRoutes.staffList.replaceFirst(':id', actingAcademyId),
        ),
        if (canViewReports) ...[
          _NavItem(
            icon: Icons.payments_outlined,
            activeIcon: Icons.payments,
            label: 'الرواتب',
            route: AppRoutes.payrollList.replaceFirst(':id', actingAcademyId),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: 'المصروفات',
            route: AppRoutes.expensesList.replaceFirst(':id', actingAcademyId),
          ),
        ],
      ],
      _NavDivider(),
      if (canViewReports)
        _NavItem(
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart,
          label: AppStrings.reports,
          route: AppRoutes.reports,
        ),
      _NavItem(
        icon: Icons.manage_accounts_outlined,
        activeIcon: Icons.manage_accounts,
        label: 'إعدادات الحساب',
        route: AppRoutes.accountSettings,
      ),
    ];
  }
}

// ─── Logo with Notification Bell ─────────────────────────────────────────────

class _SidebarLogoWithBell extends StatelessWidget {
  final String academyName;
  final int unreadCount;
  final int messagesUnread;
  final bool showMessages;
  final VoidCallback onBellTap;
  final VoidCallback onMessagesTap;

  const _SidebarLogoWithBell({
    required this.academyName,
    required this.unreadCount,
    required this.messagesUnread,
    required this.showMessages,
    required this.onBellTap,
    required this.onMessagesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_tennis,
                color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              academyName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                height: 1.15,
              ),
            ),
          ),
          // 💬 الرسائل — Badge مستقل، لمدير الأكاديمية فقط.
          if (showMessages)
            _BadgedIconButton(
              icon: Icons.chat_bubble_outline,
              count: messagesUnread,
              tooltip: 'الرسائل',
              onTap: onMessagesTap,
            ),
          // 🔔 الإشعارات — Badge مستقل.
          _BadgedIconButton(
            icon: Icons.notifications_outlined,
            count: unreadCount,
            tooltip: 'الإشعارات',
            onTap: onBellTap,
          ),
        ],
      ),
    );
  }
}

// زر أيقونة مع Badge عدّاد مستقل — يُعاد استخدامه للرسائل والإشعارات.
class _BadgedIconButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback onTap;

  const _BadgedIconButton({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(fontSize: 9, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        child: Icon(
          icon,
          color: AppColors.white.withValues(alpha: 0.8),
          size: 20,
        ),
      ),
    );
  }
}

// ─── Nav Tile ─────────────────────────────────────────────────────────────────

class _SidebarNavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.white.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: isActive
                ? const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.primary, width: 3),
                    ),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.white.withValues(alpha: 0.65),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── User Footer ──────────────────────────────────────────────────────────────

class _SidebarUserFooter extends StatelessWidget {
  final UserEntity? user;
  final VoidCallback onLogout;

  const _SidebarUserFooter({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    (user?.name.isNotEmpty == true)
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _roleLabel(user?.role),
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => openPrivacyPolicy(context),
              icon: Icon(Icons.privacy_tip_outlined,
                  size: 16, color: AppColors.white.withValues(alpha: 0.5)),
              label: Text(
                'سياسة الخصوصية',
                style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.5),
                    fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                alignment: AlignmentDirectional.centerStart,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onLogout,
              icon: Icon(Icons.logout_outlined,
                  size: 16, color: AppColors.white.withValues(alpha: 0.5)),
              label: Text(
                AppStrings.logout,
                style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.5),
                    fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                alignment: AlignmentDirectional.centerStart,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'مدير عام';
      case UserRole.academyAdmin:
        return 'مدير أكاديمية';
      case UserRole.admin:
        return 'مشرف';
      default:
        return '';
    }
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class _NavDivider {}
