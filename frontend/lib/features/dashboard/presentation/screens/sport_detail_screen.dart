import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/dashboard/presentation/providers/sport_stats_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// Per-sport statistics page (players, subscriptions, revenue, recent players).
class SportDetailScreen extends ConsumerWidget {
  final String academyId;
  final String sport;
  final String currencyLabel;

  const SportDetailScreen({
    super.key,
    required this.academyId,
    required this.sport,
    required this.currencyLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(
      sportStatsProvider(
        SportStatsParams(academyId: academyId, sport: sport),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(sport),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56.r, color: AppColors.error),
                Gap(12.h),
                Text(
                  'تعذّر تحميل إحصائيات الرياضة',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.grey700),
                ),
                Gap(16.h),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(sportStatsProvider(
                    SportStatsParams(academyId: academyId, sport: sport),
                  )),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(sportStatsProvider(
            SportStatsParams(academyId: academyId, sport: sport),
          )),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      label: 'عدد اللاعبين',
                      value: '${stats.totalPlayers}',
                      icon: Icons.group,
                      color: AppColors.secondary,
                      bg: AppColors.secondaryContainer,
                    ),
                    _StatCard(
                      label: 'اشتراكات نشطة',
                      value: '${stats.activeSubscriptions}',
                      icon: Icons.card_membership,
                      color: AppColors.success,
                      bg: AppColors.successLight,
                    ),
                    _StatCard(
                      label: 'اشتراكات منتهية',
                      value: '${stats.expiredSubscriptions}',
                      icon: Icons.event_busy,
                      color: AppColors.error,
                      bg: AppColors.errorLight,
                    ),
                    _StatCard(
                      label: 'الإيرادات',
                      value:
                          '${NumberFormat('#,##0', 'ar').format(stats.revenue.toInt())} $currencyLabel',
                      icon: Icons.payments_outlined,
                      color: AppColors.primary,
                      bg: AppColors.primaryContainer,
                    ),
                  ],
                ),
                Gap(24.h),
                Text(
                  'أحدث اللاعبين',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                Gap(8.h),
                if (stats.recentPlayers.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: Text(
                        'لا يوجد لاعبون بعد',
                        style:
                            TextStyle(fontSize: 13.sp, color: AppColors.grey400),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.recentPlayers.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: AppColors.grey100,
                        indent: 16.w,
                        endIndent: 16.w,
                      ),
                      itemBuilder: (_, i) {
                        final p = stats.recentPlayers[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20.r,
                            backgroundColor: AppColors.primaryContainer,
                            child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: p.imageUrl!,
                                      width: 40.r,
                                      height: 40.r,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                        size: 20.r,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.person,
                                    color: AppColors.primary, size: 20.r),
                          ),
                          title: Text(
                            p.fullName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                            ),
                          ),
                          subtitle: Text(
                            p.playerCode,
                            style: TextStyle(
                                fontSize: 11.sp, color: AppColors.grey500),
                          ),
                        );
                      },
                    ),
                  ),
                Gap(24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 18.r),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
