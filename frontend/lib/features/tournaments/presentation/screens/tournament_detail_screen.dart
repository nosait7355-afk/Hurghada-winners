import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/widgets/confirm_delete_dialog.dart';
import 'package:hurghada_winners/features/tournaments/data/tournament_models.dart';
import 'package:hurghada_winners/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/participant_editor_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/tournament_form_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/widgets/fixture_sheet.dart';
import 'package:hurghada_winners/features/tournaments/presentation/widgets/tournament_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// تفاصيل البطولة للإدارة: المشاركون، المباريات، الترتيب/الشجرة.
class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String academyId;
  const TournamentDetailScreen({super.key, required this.tournamentId, required this.academyId});

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> {
  bool _busy = false;

  void _reload() => ref.invalidate(tournamentDetailProvider(widget.tournamentId));

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showToast(context, success);
      _reload();
    } catch (e) {
      if (mounted) showToast(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body, {String action = 'تأكيد'}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _menu(String value, TournamentDetail d) async {
    final svc = ref.read(tournamentsServiceProvider);
    final t = d.tournament;
    switch (value) {
      case 'edit':
        final changed = await Navigator.of(context).push<Tournament>(
          MaterialPageRoute(builder: (_) => TournamentFormScreen(academyId: widget.academyId, existing: t)),
        );
        if (changed != null) _reload();
      case 'reset':
        if (await _confirm('حذف جدول المباريات', 'سترجع البطولة لمرحلة الإعداد لتعديل المشاركين والإعدادات.',
            action: 'حذف الجدول')) {
          await _run(() => svc.resetFixtures(t.id), 'تم حذف الجدول');
        }
      case 'delete':
        final ok = await confirmDelete(context, title: 'حذف البطولة', message: 'سيتم حذف "${t.name}" بكل مبارياتها ونتائجها.');
        if (ok) {
          try {
            await svc.delete(t.id);
            if (mounted) Navigator.of(context).pop();
          } catch (e) {
            if (mounted) showToast(context, errorText(e), error: true);
          }
        }
    }
  }

  Future<void> _generate(TournamentDetail d) async {
    final t = d.tournament;
    if (d.participants.length < 2) return showToast(context, 'أضف مشاركين اثنين على الأقل', error: true);
    final how = t.isDirected ? 'حسب الترتيب الذي حددته' : 'بقرعة عشوائية';
    if (!await _confirm('توليد جدول المباريات', 'سيتم إنشاء المباريات $how وإشعار اللاعبين. بعدها لا يمكن تعديل المشاركين.',
        action: 'توليد')) {
      return;
    }
    await _run(() => ref.read(tournamentsServiceProvider).generate(t.id), 'تم توليد جدول المباريات');
  }

  Future<void> _openFixture(TournamentDetail d, TournamentFixture f) async {
    if (!d.canManage) return;
    final changed = await showFixtureSheet(context, detail: d, fixture: f);
    if (changed == true) _reload();
  }

  Future<void> _editParticipant(TournamentDetail d, [TournamentParticipant? p]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ParticipantEditorScreen(detail: d, existing: p)),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tournamentDetailProvider(widget.tournamentId));
    return async.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(errorText(e, 'تعذّر تحميل البطولة')),
            Gap(10.h),
            ElevatedButton(onPressed: _reload, child: const Text('إعادة المحاولة')),
          ]),
        ),
      ),
      data: (d) {
        final t = d.tournament;
        final hasResults = d.fixtures.any((f) => f.isPlayed);
        return DefaultTabController(
          length: 3,
          initialIndex: t.isDraft ? 0 : 1,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(t.name),
              actions: [
                if (d.canManage)
                  PopupMenuButton<String>(
                    onSelected: (v) => _menu(v, d),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل البطولة')),
                      if (!t.isDraft && !hasResults) const PopupMenuItem(value: 'reset', child: Text('حذف الجدول والرجوع للإعداد')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف البطولة', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
              ],
              bottom: const TabBar(tabs: [Tab(text: 'المشاركون'), Tab(text: 'المباريات'), Tab(text: 'الترتيب')]),
            ),
            body: Column(children: [
              _Header(t: t),
              if (_busy) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: TabBarView(children: [
                  _ParticipantsTab(
                    detail: d,
                    onAdd: () => _editParticipant(d),
                    onEdit: (p) => _editParticipant(d, p),
                    onDelete: (p) async {
                      if (await _confirm('حذف المشارك', 'حذف "${p.name}" من البطولة؟', action: 'حذف')) {
                        await _run(() => ref.read(tournamentsServiceProvider).removeParticipant(t.id, p.id), 'تم الحذف');
                      }
                    },
                    onReorder: (order) =>
                        _run(() => ref.read(tournamentsServiceProvider).orderParticipants(t.id, order), 'تم حفظ الترتيب'),
                  ),
                  FixturesList(detail: d, onTapFixture: (f) => _openFixture(d, f)),
                  StandingsAndBracket(detail: d, onTapFixture: (f) => _openFixture(d, f)),
                ]),
              ),
            ]),
            bottomNavigationBar: d.canManage && t.isDraft
                ? SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : () => _generate(d),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text('توليد جدول المباريات (${d.participants.length} ${t.isTeam ? 'فريق' : 'مشارك'})'),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Tournament t;
  const _Header({required this.t});

  @override
  Widget build(BuildContext context) {
    final s = t.scoring;
    final bits = [
      formatLabels[t.format] ?? t.format,
      t.isTeam ? 'جماعية' : 'فردية',
      t.isDirected ? 'قرعة موجّهة' : 'قرعة عشوائية',
      s.isSets ? 'أفضل ${s.bestOf} أشواط (${s.pointsPerSet} نقطة)' : 'أهداف',
      if (t.hasBracket && !s.isSets) t.penaltiesEnabled ? 'ترجيح ${t.penaltiesCount} ضربات' : 'بدون ترجيح',
      if (!t.visibleToPlayers) 'مخفية عن اللاعبين',
    ];
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
      child: Row(children: [
        Expanded(child: Text(bits.join(' • '), style: TextStyle(fontSize: 12.sp, color: AppColors.grey600))),
        Gap(8.w),
        StatusChip(t.status),
      ]),
    );
  }
}

class _ParticipantsTab extends StatelessWidget {
  final TournamentDetail detail;
  final VoidCallback onAdd;
  final ValueChanged<TournamentParticipant> onEdit;
  final ValueChanged<TournamentParticipant> onDelete;
  final ValueChanged<List<String>> onReorder;
  const _ParticipantsTab({
    required this.detail,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final t = detail.tournament;
    final ps = detail.participants;
    final editable = detail.canManage && t.isDraft;
    final reorder = editable && t.isDirected;

    Widget tile(TournamentParticipant p, int i) {
      final names = p.playerIds.map((id) {
        final n = detail.player(id)?.fullName ?? '';
        return id == p.captainId ? '$n ★' : n;
      }).join('، ');
      return Padding(
        key: ValueKey(p.id),
        padding: EdgeInsets.only(bottom: 8.h),
        child: ListTile(
          tileColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: const BorderSide(color: AppColors.grey200),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryContainer,
            child: Text(reorder ? '${i + 1}' : (t.isTeam ? '${i + 1}' : p.name.characters.first),
                style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
          ),
          title: Text(p.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
          subtitle: t.isTeam
              ? Text(names, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp))
              : (p.groupIndex != null ? Text(groupName(p.groupIndex)) : null),
          onTap: detail.canManage && t.isTeam ? () => onEdit(p) : null,
          trailing: editable
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => onDelete(p),
                  ),
                  if (reorder) ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                ])
              : null,
        ),
      );
    }

    return Column(children: [
      if (reorder && ps.length > 1)
        Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(10.r)),
          child: Text('القرعة موجّهة: اسحب لترتيب المشاركين من الأقوى (1) للأضعف. '
              '${t.format == 'league' ? 'في الدوري يحدد الترتيب توزيع الجولات.' : 'في الكأس المصنف 1 يقابل الأخير.'}',
              style: TextStyle(fontSize: 12.sp)),
        ),
      Expanded(
        child: ps.isEmpty
            ? EmptyHint(
                icon: t.isTeam ? Icons.groups_outlined : Icons.person_outline,
                text: editable ? 'أضف ${t.isTeam ? 'الفرق' : 'اللاعبين'} المشاركين' : 'لا يوجد مشاركون')
            : reorder
                ? ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 120.h),
                    itemCount: ps.length,
                    itemBuilder: (_, i) => tile(ps[i], i),
                    onReorderItem: (from, to) {
                      final ids = ps.map((p) => p.id).toList();
                      ids.insert(to, ids.removeAt(from));
                      onReorder(ids);
                    },
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 120.h),
                    children: [for (var i = 0; i < ps.length; i++) tile(ps[i], i)],
                  ),
      ),
      if (editable)
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(t.isTeam ? 'إضافة فريق' : 'إضافة لاعب'),
            ),
          ),
        ),
    ]);
  }
}
