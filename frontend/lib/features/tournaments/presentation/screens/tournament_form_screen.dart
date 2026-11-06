import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/tournaments/data/tournament_models.dart';
import 'package:hurghada_winners/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:hurghada_winners/features/tournaments/presentation/widgets/tournament_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// إنشاء / تعديل بطولة. بعد توليد الجدول تُقفل الإعدادات ويُعدَّل فقط الاسم والتواريخ والظهور.
class TournamentFormScreen extends ConsumerStatefulWidget {
  final String academyId;
  final Tournament? existing;
  const TournamentFormScreen({super.key, required this.academyId, this.existing});

  @override
  ConsumerState<TournamentFormScreen> createState() => _TournamentFormScreenState();
}

class _TournamentFormScreenState extends ConsumerState<TournamentFormScreen> {
  late final TextEditingController _name, _notes, _ageGroup;
  late String _type, _format, _draw, _scoringMode;
  late int _bestOf, _pointsPerSet, _win, _draw_, _loss, _groups, _qualifiers, _penCount;
  int? _maxPoints;
  late bool _winByTwo, _double, _allowDraws, _pens, _visible;
  String? _start, _end;
  late Set<String> _branches;
  bool _saving = false;

  bool get _editing => widget.existing != null;
  bool get _locked => _editing && !widget.existing!.isDraft;

  @override
  void initState() {
    super.initState();
    final t = widget.existing ?? const Tournament(id: '', name: '');
    _name = TextEditingController(text: t.name);
    _notes = TextEditingController(text: t.notes);
    _ageGroup = TextEditingController(text: t.ageGroup);
    _type = widget.existing?.participantType ?? 'team';
    _format = t.format;
    _draw = t.drawMode;
    _scoringMode = t.scoring.mode;
    _bestOf = t.scoring.bestOf;
    _pointsPerSet = t.scoring.pointsPerSet;
    _winByTwo = t.scoring.winByTwo;
    _maxPoints = t.scoring.maxPointsPerSet;
    _win = t.league.winPoints;
    _draw_ = t.league.drawPoints;
    _loss = t.league.lossPoints;
    _double = t.league.doubleRound;
    _allowDraws = t.league.allowDraws;
    _groups = t.groupsCount;
    _qualifiers = t.qualifiersPerGroup;
    _pens = t.penaltiesEnabled;
    _penCount = t.penaltiesCount;
    _visible = t.visibleToPlayers;
    _start = t.startDate;
    _end = t.endDate;
    _branches = {...(t.academyIds.isEmpty ? [widget.academyId] : t.academyIds)};
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _ageGroup.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final cur = DateTime.tryParse((start ? _start : _end) ?? '');
    final d = await showDatePicker(
      context: context,
      initialDate: cur ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d == null) return;
    setState(() => start ? _start = DateFormat('yyyy-MM-dd').format(d) : _end = DateFormat('yyyy-MM-dd').format(d));
  }

  Map<String, dynamic> _body(bool isSuper) => {
        'name': _name.text.trim(),
        'notes': _notes.text.trim(),
        'startDate': _start,
        'endDate': _end,
        'visibleToPlayers': _visible,
        if (!_locked) ...{
          'participantType': _type,
          'format': _format,
          'drawMode': _draw,
          'ageGroup': _ageGroup.text.trim(),
          'scoring': {
            'mode': _scoringMode,
            'bestOf': _bestOf,
            'pointsPerSet': _pointsPerSet,
            'winByTwo': _winByTwo,
            'maxPointsPerSet': _maxPoints,
          },
          'league': {
            'winPoints': _win,
            'drawPoints': _draw_,
            'lossPoints': _loss,
            'doubleRound': _double,
            'allowDraws': _allowDraws,
          },
          'groups': {'count': _groups, 'qualifiersPerGroup': _qualifiers},
          'knockout': {'penaltiesEnabled': _pens, 'penaltiesCount': _penCount},
          if (isSuper) 'academyIds': _branches.toList(),
        },
      };

  Future<void> _save(bool isSuper) async {
    if (_name.text.trim().length < 2) return showToast(context, 'اكتب اسم البطولة', error: true);
    if (_start != null && _end != null && _end!.compareTo(_start!) < 0) {
      return showToast(context, 'تاريخ النهاية قبل تاريخ البداية', error: true);
    }
    if (isSuper && _branches.isEmpty) return showToast(context, 'اختر فرعاً واحداً على الأقل', error: true);
    setState(() => _saving = true);
    try {
      final svc = ref.read(tournamentsServiceProvider);
      final t = _editing ? await svc.update(widget.existing!.id, _body(isSuper)) : await svc.create(_body(isSuper));
      if (mounted) Navigator.of(context).pop(t);
    } catch (e) {
      if (mounted) showToast(context, errorText(e, 'تعذّر حفظ البطولة'), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── عناصر واجهة صغيرة ──
  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(top: 14.h, bottom: 6.h),
        child: Text(t, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: AppColors.grey700)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
      );

  Widget _choices(Map<String, String> options, String value, ValueChanged<String> onChanged) => Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: options.entries
            .map((e) => ChoiceChip(
                  label: Text(e.value),
                  selected: value == e.key,
                  onSelected: _locked ? null : (_) => setState(() => onChanged(e.key)),
                ))
            .toList(),
      );

  Widget _number(String label, int value, ValueChanged<int> onChanged, {int min = 0, int max = 100}) => Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp))),
        IconButton(
          onPressed: _locked || value <= min ? null : () => setState(() => onChanged(value - 1)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(width: 34.w, child: Text('$value', textAlign: TextAlign.center, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800))),
        IconButton(
          onPressed: _locked || value >= max ? null : () => setState(() => onChanged(value + 1)),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ]);

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged, {bool lockable = true}) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label, style: TextStyle(fontSize: 13.sp)),
        value: value,
        onChanged: lockable && _locked ? null : (v) => setState(() => onChanged(v)),
      );

  // Material (لا Container ملوّن) حتى تظهر تأثيرات اللمس لعناصر SwitchListTile بداخلها.
  Widget _card(List<Widget> children) => Padding(
        padding: EdgeInsets.only(top: 6.h),
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: const BorderSide(color: AppColors.grey200),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isSuper = ref.watch(authStateProvider).valueOrNull?.user?.isSuperAdmin == true;
    final academies = isSuper ? ref.watch(academiesProvider).valueOrNull ?? const [] : const [];
    final hasLeague = _format != 'knockout';
    final hasKo = _format != 'league';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_editing ? 'تعديل البطولة' : 'بطولة جديدة')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 120.h),
        children: [
          if (_locked)
            Container(
              margin: EdgeInsets.only(top: 8.h),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(10.r)),
              child: Text('تم توليد جدول المباريات — يمكن تعديل الاسم والتواريخ والظهور فقط.',
                  style: TextStyle(fontSize: 12.5.sp)),
            ),
          _label('اسم البطولة'),
          TextField(controller: _name, maxLength: 150, decoration: _dec('مثال: دوري الناشئين 2026')),
          if (isSuper && academies.isNotEmpty) ...[
            _label('الفروع المشاركة'),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final a in academies)
                  FilterChip(
                    label: Text(a.name),
                    selected: _branches.contains(a.id),
                    onSelected: _locked
                        ? null
                        : (v) => setState(() => v ? _branches.add(a.id) : _branches.remove(a.id)),
                  ),
              ],
            ),
          ],
          _label('نوع اللعبة'),
          _choices({'team': 'جماعية (فرق)', 'individual': 'فردية (لاعب ضد لاعب)'}, _type, (v) => _type = v),
          _label('نظام البطولة'),
          _choices(formatLabels, _format, (v) => _format = v),
          _label('القرعة'),
          _choices({'random': 'عشوائية', 'directed': 'موجّهة (أنت تحدد الترتيب)'}, _draw, (v) => _draw = v),
          _label('طريقة النتيجة'),
          _choices({'goals': 'أهداف / نقاط', 'sets': 'أشواط'}, _scoringMode, (v) => _scoringMode = v),
          if (_scoringMode == 'sets')
            _card([
              _label('عدد الأشواط'),
              _choices({'1': 'شوط واحد', '3': 'أفضل 3', '5': 'أفضل 5', '7': 'أفضل 7'}, '$_bestOf',
                  (v) => _bestOf = int.parse(v)),
              _number('نقاط الشوط', _pointsPerSet, (v) => _pointsPerSet = v, min: 1, max: 100),
              _switch('الفوز بفارق نقطتين', _winByTwo, (v) => _winByTwo = v),
              if (_winByTwo) ...[
                _switch('حد أقصى لنقاط الشوط', _maxPoints != null, (v) => _maxPoints = v ? _pointsPerSet + 9 : null),
                if (_maxPoints != null)
                  _number('الحد الأقصى', _maxPoints!, (v) => _maxPoints = v, min: _pointsPerSet + 1, max: 200),
              ],
            ]),
          if (hasLeague) ...[
            _label(_format == 'league' ? 'نقاط الدوري' : 'نقاط دور المجموعات'),
            _card([
              _number('الفوز', _win, (v) => _win = v, max: 10),
              _number('التعادل', _draw_, (v) => _draw_ = v, max: 10),
              _number('الخسارة', _loss, (v) => _loss = v, max: 10),
              _switch('ذهاب وعودة', _double, (v) => _double = v),
              if (_scoringMode == 'goals') _switch('التعادل مسموح', _allowDraws, (v) => _allowDraws = v),
            ]),
          ],
          if (_format == 'groups_knockout') ...[
            _label('المجموعات'),
            _card([
              _number('عدد المجموعات', _groups, (v) => _groups = v, min: 2, max: 16),
              _number('المتأهلون من كل مجموعة', _qualifiers, (v) => _qualifiers = v, min: 1, max: 8),
            ]),
          ],
          if (hasKo && _scoringMode == 'goals') ...[
            _label('التعادل في الكأس'),
            _card([
              _switch('ضربات ترجيح عند التعادل', _pens, (v) => _pens = v),
              if (_pens) _number('عدد الضربات', _penCount, (v) => _penCount = v, min: 1, max: 20),
            ]),
          ],
          _label('الفئة العمرية (اختياري)'),
          TextField(controller: _ageGroup, enabled: !_locked, decoration: _dec('مثال: تحت 14 سنة')),
          _label('المواعيد (اختياري)'),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(_start ?? 'البداية'),
              ),
            ),
            Gap(10.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(_end ?? 'النهاية'),
              ),
            ),
          ]),
          _switch('تظهر للاعبين في بوابتهم', _visible, (v) => _visible = v, lockable: false),
          _label('ملاحظات (اختياري)'),
          TextField(
            controller: _notes,
            maxLines: 3,
            maxLength: 1000,
            inputFormatters: [LengthLimitingTextInputFormatter(1000)],
            decoration: _dec('قواعد إضافية، الجوائز…'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: ElevatedButton(
            onPressed: _saving ? null : () => _save(isSuper),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_editing ? 'حفظ التعديلات' : 'إنشاء البطولة'),
          ),
        ),
      ),
    );
  }
}
