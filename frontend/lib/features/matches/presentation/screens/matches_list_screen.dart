import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/matches/data/match_model.dart';
import 'package:hurghada_winners/features/matches/presentation/providers/matches_providers.dart';
import 'package:hurghada_winners/features/matches/presentation/screens/create_match_screen.dart';
import 'package:hurghada_winners/features/matches/presentation/screens/match_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// قائمة مباريات الأكاديمية — بطاقات (اسم، مكان/تاريخ ووقت)، مع إمكانية
/// إضافة مباراة جديدة (مدير/سوبر أدمن/أدمن الأكاديمية).
class MatchesListScreen extends ConsumerWidget {
  final String academyId;
  const MatchesListScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesListProvider(academyId));
    final notifier = ref.read(matchesListProvider(academyId).notifier);
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final canManage =
        user?.isSuperAdmin == true || user?.isAcademyAdmin == true || user?.isAdmin == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المباريات')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CreateMatchScreen(academyId: academyId),
                  ),
                );
                if (created == true) notifier.refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('مباراة جديدة'),
            )
          : null,
      body: _body(context, ref, state, notifier),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    MatchesListState state,
    MatchesListNotifier notifier,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            SizedBox(height: 12.h),
            const Text('تعذّر تحميل المباريات'),
            SizedBox(height: 12.h),
            ElevatedButton(onPressed: notifier.refresh, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis_outlined, size: 52.sp, color: AppColors.grey400),
            SizedBox(height: 12.h),
            Text('لا توجد مباريات بعد',
                style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
            notifier.loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 90.h),
          itemCount: state.items.length + (state.loadingMore ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final match = state.items[index];
            return _MatchTile(
              match: match,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MatchDetailScreen(
                      matchId: match.id,
                      academyId: academyId,
                    ),
                  ),
                );
                notifier.refresh();
              },
            );
          },
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  const _MatchTile({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_tennis, color: AppColors.primary, size: 22.sp),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.name,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(4.h),
                    Text(
                      '${match.location} • ${match.date} ${match.time}',
                      style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(6.h),
                    Row(
                      children: [
                        Icon(Icons.group_outlined, size: 14.sp, color: AppColors.grey400),
                        Gap(4.w),
                        Text('${match.playersCount} لاعب',
                            style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey500)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: AppColors.grey300),
            ],
          ),
        ),
      ),
    );
  }
}
