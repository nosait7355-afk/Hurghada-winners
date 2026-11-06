// عروض مشتركة بين شاشة الإدارة وبوابة اللاعب: قائمة المباريات، جدول الترتيب، شجرة الكأس.
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/features/tournaments/data/tournament_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

String errorText(Object e, [String fallback = 'حدث خطأ، حاول مرة أخرى']) =>
    e is AppException && e.message.isNotEmpty ? e.message : fallback;

void showToast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: error ? AppColors.error : AppColors.success),
  );
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'running' => AppColors.primary,
      'finished' => AppColors.success,
      _ => AppColors.warning,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20.r)),
      child: Text(statusLabels[status] ?? status,
          style: TextStyle(color: color, fontSize: 11.5.sp, fontWeight: FontWeight.w700)),
    );
  }
}

class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyHint({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48.sp, color: AppColors.grey400),
            Gap(10.h),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500, fontSize: 14.sp)),
          ]),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 8.h),
        child: Text(text, style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: AppColors.grey800)),
      );
}

/// بطاقة مباراة واحدة.
class FixtureCard extends StatelessWidget {
  final TournamentDetail detail;
  final TournamentFixture fixture;
  final VoidCallback? onTap;
  final bool highlight;
  const FixtureCard({super.key, required this.detail, required this.fixture, this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final f = fixture;
    Widget side(String? id, {required bool winner}) => Expanded(
          child: Text(
            f.isBye && id == null ? 'صعود مباشر' : detail.nameOf(id),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: winner ? FontWeight.w800 : FontWeight.w600,
              color: id == null ? AppColors.grey400 : (winner ? AppColors.success : AppColors.grey800),
            ),
          ),
        );
    final when = [f.date, f.time].whereType<String>().join(' ');
    final extra = [
      if (f.sets.isNotEmpty) 'الأشواط: ${f.sets.map((x) => '${x.a}-${x.b}').join('، ')}',
      if (f.penaltiesA != null) 'ترجيح ${f.penaltiesA} - ${f.penaltiesB}',
      if (when.isNotEmpty) when,
      if (f.location.isNotEmpty) f.location,
    ];
    return Material(
      color: highlight ? AppColors.primaryContainer : AppColors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: highlight ? AppColors.primary : AppColors.grey200),
          ),
          child: Column(children: [
            Row(children: [
              side(f.aId, winner: f.winnerId != null && f.winnerId == f.aId),
              SizedBox(
                width: 80.w,
                child: Text(
                  f.isPlayed ? '${f.scoreA} - ${f.scoreB}' : (f.isBye ? '—' : 'ضد'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: f.isPlayed ? 17.sp : 12.sp,
                    fontWeight: FontWeight.w800,
                    color: f.isPlayed ? AppColors.secondary : AppColors.grey500,
                  ),
                ),
              ),
              side(f.bId, winner: f.winnerId != null && f.winnerId == f.bId),
            ]),
            if (extra.isNotEmpty) ...[
              Gap(6.h),
              Text(extra.join(' • '),
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey500)),
            ],
          ]),
        ),
      ),
    );
  }
}

/// كل المباريات مقسّمة: المجموعات/الجولات ثم أدوار الكأس.
class FixturesList extends StatelessWidget {
  final TournamentDetail detail;
  final void Function(TournamentFixture)? onTapFixture;
  final String? highlightParticipant;
  final bool onlyMine;
  const FixturesList({super.key, required this.detail, this.onTapFixture, this.highlightParticipant, this.onlyMine = false});

  @override
  Widget build(BuildContext context) {
    final fx = detail.fixtures.where((f) => !onlyMine || f.involves(highlightParticipant)).toList();
    if (fx.isEmpty) {
      return EmptyHint(
        icon: Icons.event_note_outlined,
        text: detail.tournament.isDraft ? 'لم يتم توليد جدول المباريات بعد' : 'لا توجد مباريات',
      );
    }
    final children = <Widget>[];
    String? lastHeader;
    final totalKo = detail.knockoutRounds;
    for (final f in fx) {
      final header = switch (f.stage) {
        'group' => '${groupName(f.groupIndex)} — الجولة ${f.round}',
        'knockout' => knockoutRoundName(f.round, totalKo),
        _ => 'الجولة ${f.round}',
      };
      if (header != lastHeader) {
        children.add(SectionTitle(header));
        lastHeader = header;
      }
      children.add(Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: FixtureCard(
          detail: detail,
          fixture: f,
          highlight: f.involves(highlightParticipant),
          onTap: onTapFixture == null ? null : () => onTapFixture!(f),
        ),
      ));
    }
    return ListView(padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 120.h), children: children);
  }
}

/// جدول الترتيب (دوري أو كل مجموعة).
class StandingsTable extends StatelessWidget {
  final TournamentDetail detail;
  final StandingsGroup group;
  final String? highlightParticipant;
  const StandingsTable({super.key, required this.detail, required this.group, this.highlightParticipant});

  @override
  Widget build(BuildContext context) {
    final sets = detail.tournament.scoring.isSets;
    final qualifiers = detail.tournament.format == 'groups_knockout' ? detail.tournament.qualifiersPerGroup : 0;
    final head = TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: AppColors.grey600);
    Widget cell(String t, {TextStyle? style, double? w}) => SizedBox(
          width: w ?? 32.w,
          child: Text(t, textAlign: TextAlign.center, style: style ?? TextStyle(fontSize: 12.5.sp)),
        );
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(children: [
              cell('#', style: head, w: 26.w),
              SizedBox(width: 130.w, child: Text(detail.tournament.isTeam ? 'الفريق' : 'اللاعب', style: head)),
              cell('لعب', style: head),
              cell('فاز', style: head),
              cell('تعادل', style: head, w: 40.w),
              cell('خسر', style: head),
              cell(sets ? 'أشواط' : 'له', style: head, w: 42.w),
              cell('عليه', style: head, w: 36.w),
              cell('±', style: head),
              cell('نقاط', style: head, w: 40.w),
            ]),
          ),
          const Divider(height: 1),
          for (final r in group.rows)
            Container(
              color: r.id == highlightParticipant
                  ? AppColors.primaryContainer
                  : (r.position <= qualifiers ? AppColors.successLight : null),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
              child: Row(children: [
                cell('${r.position}', w: 26.w, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700)),
                SizedBox(
                  width: 130.w,
                  child: Text(detail.nameOf(r.id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                ),
                cell('${r.played}'),
                cell('${r.won}'),
                cell('${r.drawn}', w: 40.w),
                cell('${r.lost}'),
                cell('${r.goalsFor}', w: 42.w),
                cell('${r.against}', w: 36.w),
                cell(r.diff > 0 ? '+${r.diff}' : '${r.diff}'),
                cell('${r.points}',
                    w: 40.w, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.secondary)),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// تبويب الترتيب: جداول المجموعات/الدوري ثم شجرة الكأس.
class StandingsAndBracket extends StatelessWidget {
  final TournamentDetail detail;
  final String? highlightParticipant;
  final void Function(TournamentFixture)? onTapFixture;
  const StandingsAndBracket({super.key, required this.detail, this.highlightParticipant, this.onTapFixture});

  @override
  Widget build(BuildContext context) {
    final t = detail.tournament;
    if (t.isDraft) {
      return const EmptyHint(icon: Icons.leaderboard_outlined, text: 'الترتيب يظهر بعد توليد جدول المباريات');
    }
    final children = <Widget>[];
    if (t.hasLeagueTable) {
      for (final g in detail.standings) {
        children.add(SectionTitle(g.groupIndex == null ? 'جدول الترتيب' : groupName(g.groupIndex)));
        children.add(StandingsTable(detail: detail, group: g, highlightParticipant: highlightParticipant));
      }
    }
    if (t.hasBracket) {
      children.add(const SectionTitle('شجرة الكأس'));
      children.add(detail.knockout.isEmpty
          ? Padding(
              padding: EdgeInsets.all(12.r),
              child: Text('تُنشأ الشجرة تلقائياً بعد انتهاء مباريات المجموعات',
                  style: TextStyle(color: AppColors.grey500, fontSize: 13.sp)),
            )
          : BracketView(detail: detail, highlightParticipant: highlightParticipant, onTapFixture: onTapFixture));
    }
    return ListView(padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 120.h), children: children);
  }
}

/// شجرة الكأس: عمود لكل دور، قابلة للتمرير أفقياً.
class BracketView extends StatelessWidget {
  final TournamentDetail detail;
  final String? highlightParticipant;
  final void Function(TournamentFixture)? onTapFixture;
  const BracketView({super.key, required this.detail, this.highlightParticipant, this.onTapFixture});

  @override
  Widget build(BuildContext context) {
    final total = detail.knockoutRounds;
    final ko = detail.knockout;
    final firstCount = ko.where((f) => f.round == 1).length;
    final slot = 78.h;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var r = 1; r <= total; r++)
            SizedBox(
              width: 170.w,
              child: Column(children: [
                Text(knockoutRoundName(r, total),
                    style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: AppColors.grey700)),
                Gap(8.h),
                SizedBox(
                  height: firstCount * slot,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final f in (ko.where((x) => x.round == r).toList()
                        ..sort((a, b) => a.matchNo.compareTo(b.matchNo))))
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: _BracketBox(
                            detail: detail,
                            fixture: f,
                            highlight: f.involves(highlightParticipant),
                            onTap: onTapFixture == null ? null : () => onTapFixture!(f),
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _BracketBox extends StatelessWidget {
  final TournamentDetail detail;
  final TournamentFixture fixture;
  final bool highlight;
  final VoidCallback? onTap;
  const _BracketBox({required this.detail, required this.fixture, required this.highlight, this.onTap});

  @override
  Widget build(BuildContext context) {
    final f = fixture;
    Widget line(String? id, int? score, int? pens) {
      final win = f.winnerId != null && f.winnerId == id;
      return Row(children: [
        Expanded(
          child: Text(
            id == null ? (f.isBye ? '—' : 'لم يتحدد') : detail.nameOf(id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: win ? FontWeight.w800 : FontWeight.w500,
              color: id == null ? AppColors.grey400 : (win ? AppColors.success : AppColors.grey800),
            ),
          ),
        ),
        if (score != null)
          Text(pens != null ? '$score ($pens)' : '$score', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800)),
      ]);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primaryContainer : AppColors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: highlight ? AppColors.primary : AppColors.grey300),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          line(f.aId, f.scoreA, f.penaltiesA),
          Divider(height: 8.h),
          line(f.bId, f.scoreB, f.penaltiesB),
        ]),
      ),
    );
  }
}
