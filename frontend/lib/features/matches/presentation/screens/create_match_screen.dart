import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/matches/data/matches_service.dart';
import 'package:hurghada_winners/features/matches/presentation/screens/match_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// إنشاء مباراة جديدة: اسم، مكان، تاريخ، وقت، ملاحظات (اختياري)، ورياضة
/// (فقط للأكاديميات متعددة الرياضات).
class CreateMatchScreen extends ConsumerStatefulWidget {
  final String academyId;
  const CreateMatchScreen({super.key, required this.academyId});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String? _selectedSport;
  bool _submitting = false;
  String? _error;

  MatchesService get _service => sl<MatchesService>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit(bool isMultiSport) async {
    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'اسم المباراة مطلوب');
      return;
    }
    if (location.isEmpty) {
      setState(() => _error = 'المكان مطلوب');
      return;
    }
    if (_date == null) {
      setState(() => _error = 'اختر التاريخ');
      return;
    }
    if (_time == null) {
      setState(() => _error = 'اختر الوقت');
      return;
    }
    if (isMultiSport && (_selectedSport == null || _selectedSport!.isEmpty)) {
      setState(() => _error = 'اختر الرياضة');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_date!);
    final timeStr =
        '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

    try {
      final match = await _service.createMatch(
        name: name,
        location: location,
        date: dateStr,
        time: timeStr,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        sport: isMultiSport ? _selectedSport : null,
        academyId: widget.academyId,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MatchDetailScreen(matchId: match.id, academyId: widget.academyId),
        ),
      );
    } catch (_) {
      setState(() {
        _submitting = false;
        _error = 'تعذّر إنشاء المباراة. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final academyAsync = ref.watch(academyByIdProvider(widget.academyId));
    final academy = academyAsync.valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    final sports = academy?.sports ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('مباراة جديدة')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMultiSport) ...[
              _label('الرياضة'),
              Gap(6.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedSport,
                decoration: _decoration(hint: 'اختر الرياضة'),
                items: sports
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSport = v),
              ),
              Gap(16.h),
            ],
            _label('اسم المباراة'),
            Gap(6.h),
            TextField(
              controller: _nameCtrl,
              maxLength: 150,
              decoration: _decoration(hint: 'مثال: مباراة ودية مع أكاديمية النصر'),
            ),
            Gap(10.h),
            _label('المكان'),
            Gap(6.h),
            TextField(
              controller: _locationCtrl,
              maxLength: 150,
              decoration: _decoration(hint: 'مثال: ملعب الأكاديمية'),
            ),
            Gap(16.h),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'التاريخ',
                    value: _date == null
                        ? 'اختر التاريخ'
                        : DateFormat('yyyy-MM-dd').format(_date!),
                    icon: Icons.calendar_today_outlined,
                    onTap: _pickDate,
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: _PickerField(
                    label: 'الوقت',
                    value: _time == null ? 'اختر الوقت' : _time!.format(context),
                    icon: Icons.access_time_outlined,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            Gap(16.h),
            _label('ملاحظات (اختياري)'),
            Gap(6.h),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              maxLength: 1000,
              decoration: _decoration(hint: 'أي تفاصيل إضافية'),
            ),
            if (_error != null) ...[
              Gap(8.h),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            Gap(16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : () => _submit(isMultiSport),
                child: _submitting
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('إنشاء المباراة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.grey700),
      );

  InputDecoration _decoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.grey700)),
        Gap(6.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18.sp, color: AppColors.grey500),
                Gap(8.w),
                Expanded(
                  child: Text(value,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.grey900),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
