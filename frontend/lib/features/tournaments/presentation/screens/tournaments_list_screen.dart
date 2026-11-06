import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/tournaments/data/tournament_models.dart';
import 'package:hurghada_winners/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/tournament_detail_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/tournament_form_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/widgets/tournament_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// بطولات الفرع (دوري / كأس / مجموعات) — للإدارة.
class TournamentsListScreen extends ConsumerWidget {
  final String academyId;
  const TournamentsListScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentsListProvider(academyId));

    Future<void> open(String id) async {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TournamentDetailScreen(tournamentId: id, academyId: academyId),
      ));
      ref.invalidate(tournamentsListProvider(academyId));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('البطولات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<Tournament>(
            MaterialPageRoute(builder: (_) => TournamentFormScreen(academyId: academyId)),
          );
          ref.invalidate(tournamentsListProvider(academyId));
          if (created != null) await open(created.id);
        },
        icon: const Icon(Icons.add),
        label: const Text('بطولة جديدة'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            Gap(10.h),
            Text(errorText(e, 'تعذّر تحميل البطولات')),
            Gap(10.h),
            ElevatedButton(
              onPressed: () => ref.invalidate(tournamentsListProvider(academyId)),
              child: const Text('إعادة المحاولة'),
            ),
          ]),
        ),
        data: (items) => items.isEmpty
            ? const EmptyHint(
                icon: Icons.emoji_events_outlined, text: 'لا توجد بطولات بعد\nأنشئ دوري أو كأس من الزر بالأسفل')
            : RefreshIndicator(
                onRefresh: () => ref.refresh(tournamentsListProvider(academyId).future),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 100.h),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Gap(10.h),
                  itemBuilder: (_, i) => TournamentTile(t: items[i], onTap: () => open(items[i].id)),
                ),
              ),
      ),
    );
  }
}

class TournamentTile extends StatelessWidget {
  final Tournament t;
  final VoidCallback onTap;
  final bool showMine;
  const TournamentTile({super.key, required this.t, required this.onTap, this.showMine = false});

  @override
  Widget build(BuildContext context) {
    final sub = [
      formatLabels[t.format] ?? t.format,
      t.isTeam ? 'فرق' : 'فردي',
      if (t.participantsCount > 0) '${t.participantsCount} ${t.isTeam ? 'فريق' : 'مشارك'}',
      if (t.startDate != null) t.startDate!,
    ].join(' • ');
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
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(Icons.emoji_events, color: AppColors.warning, size: 22.sp),
            ),
            Gap(12.w),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(t.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                  ),
                  StatusChip(t.status),
                ]),
                Gap(4.h),
                Text(sub, style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
                if (showMine && t.isParticipant) ...[
                  Gap(4.h),
                  Text('أنت مشارك في هذه البطولة',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ]),
            ),
            const Icon(Icons.chevron_left, color: AppColors.grey300),
          ]),
        ),
      ),
    );
  }
}
