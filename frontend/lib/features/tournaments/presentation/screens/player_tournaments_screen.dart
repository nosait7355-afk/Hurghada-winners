import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/tournaments/data/tournament_models.dart';
import 'package:hurghada_winners/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/tournaments_list_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/widgets/tournament_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// بوابة اللاعب: بطولات فرعه (قراءة فقط) — بطولاته أولاً.
class PlayerTournamentsScreen extends ConsumerWidget {
  const PlayerTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerTournamentsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('البطولات')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(errorText(e, 'تعذّر تحميل البطولات')),
            Gap(10.h),
            ElevatedButton(
                onPressed: () => ref.invalidate(playerTournamentsProvider), child: const Text('إعادة المحاولة')),
          ]),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyHint(icon: Icons.emoji_events_outlined, text: 'لا توجد بطولات حالياً');
          }
          final sorted = [...items]..sort((a, b) => (b.isParticipant ? 1 : 0) - (a.isParticipant ? 1 : 0));
          return RefreshIndicator(
            onRefresh: () => ref.refresh(playerTournamentsProvider.future),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 100.h),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => Gap(10.h),
              itemBuilder: (_, i) => TournamentTile(
                t: sorted[i],
                showMine: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PlayerTournamentDetailScreen(tournamentId: sorted[i].id),
                )),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlayerTournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;
  const PlayerTournamentDetailScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerTournamentDetailProvider(tournamentId));
    return async.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(errorText(e, 'تعذّر تحميل البطولة')),
            Gap(10.h),
            ElevatedButton(
              onPressed: () => ref.invalidate(playerTournamentDetailProvider(tournamentId)),
              child: const Text('إعادة المحاولة'),
            ),
          ]),
        ),
      ),
      data: (d) {
        final mine = d.myParticipantId;
        final tabs = [
          if (mine != null) const Tab(text: 'مبارياتي'),
          const Tab(text: 'كل المباريات'),
          const Tab(text: 'الترتيب'),
        ];
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: Text(d.tournament.name), bottom: TabBar(tabs: tabs)),
            body: Column(children: [
              _MyCard(detail: d),
              Expanded(
                child: TabBarView(children: [
                  if (mine != null) FixturesList(detail: d, highlightParticipant: mine, onlyMine: true),
                  FixturesList(detail: d, highlightParticipant: mine),
                  StandingsAndBracket(detail: d, highlightParticipant: mine),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/// بطاقة أعلى الصفحة: نوع البطولة + فريق اللاعب وزملاؤه + مركزه.
class _MyCard extends StatelessWidget {
  final TournamentDetail detail;
  const _MyCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final t = detail.tournament;
    final me = detail.participant(detail.myParticipantId);
    StandingRow? row;
    for (final g in detail.standings) {
      for (final r in g.rows) {
        if (r.id == me?.id) row = r;
      }
    }
    final info = [
      formatLabels[t.format] ?? t.format,
      t.isTeam ? 'جماعية' : 'فردية',
      if (t.startDate != null) 'تبدأ ${t.startDate}',
    ].join(' • ');
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(info, style: TextStyle(fontSize: 12.sp, color: AppColors.grey600))),
          StatusChip(t.status),
        ]),
        if (me != null) ...[
          Gap(8.h),
          Row(children: [
            Icon(t.isTeam ? Icons.groups : Icons.person, color: AppColors.primary, size: 20.sp),
            Gap(6.w),
            Expanded(
              child: Text(t.isTeam ? 'فريقك: ${me.name}' : 'أنت مشارك في البطولة',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
            ),
            if (row != null)
              Text('المركز ${row.position} • ${row.points} نقطة',
                  style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: AppColors.secondary)),
          ]),
          if (t.isTeam && me.playerIds.length > 1) ...[
            Gap(4.h),
            Text(
              me.playerIds.map((id) {
                final n = detail.player(id)?.fullName ?? '';
                return id == me.captainId ? '$n (الكابتن)' : n;
              }).join('، '),
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey600),
            ),
          ],
        ],
        if (t.notes.isNotEmpty) ...[
          Gap(6.h),
          Text(t.notes, style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
        ],
      ]),
    );
  }
}
