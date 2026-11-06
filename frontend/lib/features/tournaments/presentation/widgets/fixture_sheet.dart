import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/tournaments/data/tournament_models.dart';
import 'package:hurghada_winners/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:hurghada_winners/features/tournaments/presentation/widgets/tournament_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// نافذة المباراة للأدمن: تسجيل/مسح النتيجة، الموعد والمكان، وتغيير الطرفين (قرعة موجّهة).
/// تعيد true إذا تغيّر شيء.
Future<bool?> showFixtureSheet(BuildContext context,
    {required TournamentDetail detail, required TournamentFixture fixture}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18.r))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _FixtureSheet(detail: detail, fixture: fixture),
    ),
  );
}

class _FixtureSheet extends ConsumerStatefulWidget {
  final TournamentDetail detail;
  final TournamentFixture fixture;
  const _FixtureSheet({required this.detail, required this.fixture});

  @override
  ConsumerState<_FixtureSheet> createState() => _FixtureSheetState();
}

class _FixtureSheetState extends ConsumerState<_FixtureSheet> {
  late final TextEditingController _a, _b, _pa, _pb, _location;
  late final List<(TextEditingController, TextEditingController)> _sets;
  String? _date, _time, _sideA, _sideB;
  bool _saving = false;

  TournamentFixture get f => widget.fixture;
  Tournament get t => widget.detail.tournament;
  ScoringRules get s => t.scoring;

  bool get _canScore => f.isReady && !t.isDraft;
  bool get _canChangeSides =>
      f.status == 'pending' &&
      !f.isBye &&
      !(f.stage == 'knockout' && f.round > 1) &&
      !widget.detail.fixtures.any((x) => x.isPlayed);

  @override
  void initState() {
    super.initState();
    _a = TextEditingController(text: f.isPlayed && !s.isSets ? '${f.scoreA}' : '');
    _b = TextEditingController(text: f.isPlayed && !s.isSets ? '${f.scoreB}' : '');
    _pa = TextEditingController(text: f.penaltiesA?.toString() ?? '');
    _pb = TextEditingController(text: f.penaltiesB?.toString() ?? '');
    _location = TextEditingController(text: f.location);
    _sets = List.generate(s.bestOf, (i) {
      final has = i < f.sets.length;
      return (
        TextEditingController(text: has ? '${f.sets[i].a}' : ''),
        TextEditingController(text: has ? '${f.sets[i].b}' : ''),
      );
    });
    _date = f.date;
    _time = f.time;
    _sideA = f.aId;
    _sideB = f.bId;
    for (final c in [_a, _b]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_a, _b, _pa, _pb, _location, for (final p in _sets) ...[p.$1, p.$2]]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _n(TextEditingController c) => int.tryParse(c.text.trim());

  bool get _needsPenalties =>
      f.stage == 'knockout' && !s.isSets && t.penaltiesEnabled && _n(_a) != null && _n(_a) == _n(_b);

  Future<void> _act(Future<void> Function() action, String ok) async {
    setState(() => _saving = true);
    try {
      await action();
      if (mounted) {
        showToast(context, ok);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showToast(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveResult() async {
    final Map<String, dynamic> body;
    if (s.isSets) {
      final sets = <Map<String, int>>[];
      for (final (ca, cb) in _sets) {
        final a = _n(ca), b = _n(cb);
        if (a == null && b == null) continue;
        if (a == null || b == null) return showToast(context, 'أكمل نتيجة كل شوط', error: true);
        sets.add({'a': a, 'b': b});
      }
      if (sets.isEmpty) return showToast(context, 'أدخل نتيجة الأشواط', error: true);
      body = {'sets': sets};
    } else {
      final a = _n(_a), b = _n(_b);
      if (a == null || b == null) return showToast(context, 'أدخل النتيجة', error: true);
      body = {'scoreA': a, 'scoreB': b};
      if (_needsPenalties) {
        final pa = _n(_pa), pb = _n(_pb);
        if (pa == null || pb == null || pa == pb) {
          return showToast(context, 'أدخل نتيجة ضربات الترجيح بفائز واضح', error: true);
        }
        body.addAll({'penaltiesA': pa, 'penaltiesB': pb});
      }
    }
    await _act(() => ref.read(tournamentsServiceProvider).recordResult(t.id, f.id, body), 'تم تسجيل النتيجة');
  }

  Future<void> _saveSchedule() async {
    final body = <String, dynamic>{'date': _date, 'time': _time, 'location': _location.text.trim()};
    if (_canChangeSides && (_sideA != f.aId || _sideB != f.bId)) {
      if (_sideA == null || _sideB == null || _sideA == _sideB) {
        return showToast(context, 'اختر طرفين مختلفين', error: true);
      }
      body.addAll({'aId': _sideA, 'bId': _sideB});
    }
    await _act(() => ref.read(tournamentsServiceProvider).updateFixture(t.id, f.id, body), 'تم حفظ المباراة');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date ?? '') ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d != null) setState(() => _date = DateFormat('yyyy-MM-dd').format(d));
  }

  Future<void> _pickTime() async {
    final parts = (_time ?? '').split(':');
    final tm = await showTimePicker(
      context: context,
      initialTime: parts.length == 2
          ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 17, minute: int.tryParse(parts[1]) ?? 0)
          : const TimeOfDay(hour: 17, minute: 0),
    );
    if (tm != null) {
      setState(() => _time = '${tm.hour.toString().padLeft(2, '0')}:${tm.minute.toString().padLeft(2, '0')}');
    }
  }

  Widget _numField(TextEditingController c, {String? hint}) => SizedBox(
        width: 64.w,
        child: TextField(
          controller: c,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
      );

  Widget _scoreRow(String label, TextEditingController a, TextEditingController b) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Row(children: [
          SizedBox(width: 70.w, child: Text(label, style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey600))),
          const Spacer(),
          _numField(a),
          Padding(padding: EdgeInsets.symmetric(horizontal: 10.w), child: const Text('-')),
          _numField(b),
          const Spacer(),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final sideOptions = d.participants
        .where((p) => f.stage != 'group' || p.groupIndex == f.groupIndex)
        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)))
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(4))),
        ),
        Gap(12.h),
        Row(children: [
          Expanded(child: Text(d.nameOf(f.aId), textAlign: TextAlign.center, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800))),
          Text('ضد', style: TextStyle(color: AppColors.grey500, fontSize: 12.sp)),
          Expanded(child: Text(d.nameOf(f.bId), textAlign: TextAlign.center, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800))),
        ]),
        if (f.isBye)
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: const Text('صعود مباشر — لا توجد مباراة', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500)),
          ),

        // ── النتيجة ──
        if (_canScore) ...[
          const SectionTitle('النتيجة'),
          if (s.isSets) ...[
            Text('أفضل ${s.bestOf} أشواط — الشوط ${s.pointsPerSet} نقطة${s.winByTwo ? ' بفارق نقطتين' : ''}. اترك الأشواط غير الملعوبة فارغة.',
                style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey500)),
            Gap(8.h),
            for (var i = 0; i < _sets.length; i++) _scoreRow('الشوط ${i + 1}', _sets[i].$1, _sets[i].$2),
          ] else ...[
            _scoreRow('النتيجة', _a, _b),
            if (_needsPenalties) ...[
              Text('تعادل — أدخل نتيجة ضربات الترجيح (${t.penaltiesCount} ضربات)',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.warning, fontWeight: FontWeight.w700)),
              Gap(6.h),
              _scoreRow('الترجيح', _pa, _pb),
            ],
          ],
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _saveResult,
                child: Text(f.isPlayed ? 'تعديل النتيجة' : 'حفظ النتيجة'),
              ),
            ),
            if (f.isPlayed) ...[
              Gap(8.w),
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => _act(() => ref.read(tournamentsServiceProvider).clearResult(t.id, f.id), 'تم مسح النتيجة'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('مسح النتيجة'),
              ),
            ],
          ]),
        ] else if (!f.isBye && !t.isDraft)
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: const Text('تُسجَّل النتيجة بعد تحديد طرفي المباراة', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500)),
          ),

        // ── الموعد والطرفان ──
        if (!f.isBye) ...[
          const SectionTitle('الموعد والمكان'),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(_date ?? 'التاريخ'),
              ),
            ),
            Gap(8.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time, size: 18),
                label: Text(_time ?? 'الوقت'),
              ),
            ),
          ]),
          Gap(8.h),
          TextField(
            controller: _location,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'المكان (اختياري)',
              isDense: true,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          if (_canChangeSides && sideOptions.length >= 2) ...[
            Text('طرفا المباراة (قبل تسجيل أي نتيجة)', style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey600)),
            Gap(6.h),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sideA,
                  isExpanded: true,
                  items: sideOptions,
                  onChanged: (v) => setState(() => _sideA = v),
                ),
              ),
              Gap(8.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sideB,
                  isExpanded: true,
                  items: sideOptions,
                  onChanged: (v) => setState(() => _sideB = v),
                ),
              ),
            ]),
            Gap(8.h),
          ],
          OutlinedButton(onPressed: _saving ? null : _saveSchedule, child: const Text('حفظ الموعد')),
        ],
      ]),
    );
  }
}
