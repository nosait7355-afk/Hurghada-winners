import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/player/data/player_account_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// إحصائية حسابات اللاعبين: { portalEnabled, withAccount, withoutAccount }.
/// مفتاح العائلة = academyId (فارغ = أكاديمية المستخدم الحالي).
final playerAccountsStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, academyId) async {
  return sl<PlayerAccountService>()
      .accountStats(academyId: academyId.isEmpty ? null : academyId);
});

/// بطاقة لوحة التحكم: عدد اللاعبين الذين لديهم حسابات / بدون حسابات.
/// تختفي تلقائياً إذا كانت ميزة بوابة اللاعب غير مفعّلة للأكاديمية.
/// نفس الـ Widget لكل المنصات (Android / Windows / Flutter Web).
class PlayerAccountsStatsCard extends ConsumerWidget {
  final String? academyId;
  const PlayerAccountsStatsCard({super.key, this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerAccountsStatsProvider(academyId ?? ''));
    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats['portalEnabled'] != true) return const SizedBox.shrink();
        final withAccount = (stats['withAccount'] as num?)?.toInt() ?? 0;
        final withoutAccount = (stats['withoutAccount'] as num?)?.toInt() ?? 0;

        return Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_circle_outlined,
                      size: 20.sp, color: AppColors.primary),
                  Gap(8.w),
                  Text(
                    'حسابات اللاعبين',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                ],
              ),
              Gap(12.h),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'لديهم حسابات',
                      value: withAccount,
                      color: AppColors.success,
                      bg: AppColors.successLight,
                      icon: Icons.how_to_reg_outlined,
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: _MiniStat(
                      label: 'بدون حسابات',
                      value: withoutAccount,
                      color: AppColors.warning,
                      bg: AppColors.warningLight,
                      icon: Icons.no_accounts_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22.sp, color: color),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
