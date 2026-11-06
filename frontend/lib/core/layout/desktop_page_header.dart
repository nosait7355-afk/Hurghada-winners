// Shared top header bar for Desktop/Tablet content (title + subtitle on the
// right, optional action buttons/refresh on the left — RTL). Matches the
// header used on the Dashboard reference (_DesktopPageHeader there is the
// dashboard-specific instance of this same pattern).
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class DesktopPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const DesktopPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey500),
                ),
            ],
          ),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

class DesktopRefreshButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  const DesktopRefreshButton({
    super.key,
    required this.onPressed,
    this.label = 'تحديث',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.refresh_outlined, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.grey700,
        side: const BorderSide(color: AppColors.grey300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class DesktopPrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  const DesktopPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
    );
  }
}
