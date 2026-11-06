// Tablet tier (700–1199px). Reuses the same persistent sidebar as
// DesktopShell — the Windows reference has no tablet tier of its own, so this
// keeps the same chrome and lets the content area adapt its own grid columns.
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/layout/desktop_shell.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TabletShell extends ConsumerWidget {
  final String location;
  final Widget child;

  const TabletShell({super.key, required this.location, required this.child});

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
