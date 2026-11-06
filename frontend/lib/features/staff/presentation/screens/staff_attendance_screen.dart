import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/staff/data/staff_scan_service.dart';
import 'package:hurghada_winners/features/staff/domain/entities/staff_attendance_entity.dart';
import 'package:hurghada_winners/features/staff/domain/entities/staff_entity.dart';
import 'package:hurghada_winners/features/staff/presentation/providers/staff_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  final StaffEntity staff;
  const StaffAttendanceScreen({super.key, required this.staff});

  @override
  ConsumerState<StaffAttendanceScreen> createState() =>
      _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  // الشهر المعروض في السجل (أول يوم فيه).
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static const _weekdayAr = {
    DateTime.saturday: 'السبت',
    DateTime.sunday: 'الأحد',
    DateTime.monday: 'الإثنين',
    DateTime.tuesday: 'الثلاثاء',
    DateTime.wednesday: 'الأربعاء',
    DateTime.thursday: 'الخميس',
    DateTime.friday: 'الجمعة',
  };

  DateTime get _monthEnd {
    final last = DateTime(_month.year, _month.month + 1, 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return last.isAfter(today) ? today : last;
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _month = next);
    _loadHistory();
  }

  void _showQr() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('QR: ${widget.staff.fullName}', textAlign: TextAlign.center),
        content: SizedBox(
          width: 240,
          height: 240,
          child: QrImageView(
            data: staffQrData(widget.staff.id),
            version: QrVersions.auto,
            backgroundColor: Colors.white,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  /// أيام الشهر (الأحدث أولاً): كل يوم له سجل، وكل يوم عمل بلا سجل = غياب.
  List<({DateTime date, StaffAttendanceEntity? record})> _buildDays(
      List<StaffAttendanceEntity> records) {
    final byDate = {for (final r in records) r.date: r};
    final hire = widget.staff.hireDate;
    final hireDay = DateTime(hire.year, hire.month, hire.day);
    final out = <({DateTime date, StaffAttendanceEntity? record})>[];
    for (var d = _monthEnd;
        !d.isBefore(_month);
        d = DateTime(d.year, d.month, d.day - 1)) {
      final r = byDate[DateFormat('yyyy-MM-dd').format(d)];
      final workDay = widget.staff.workingDays.contains(_weekdayAr[d.weekday]);
      if (r != null || (workDay && !d.isBefore(hireDay))) {
        out.add((date: d, record: r));
      }
    }
    return out;
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    ref.read(staffAttendanceProvider.notifier).loadHistory(
          staffId: widget.staff.id,
          startDate: DateFormat('yyyy-MM-dd').format(_month),
          endDate: DateFormat('yyyy-MM-dd').format(_monthEnd),
          academyId: widget.staff.academyId,
        );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _mark(String status) async {
    setState(() => _isSubmitting = true);
    final error =
        await ref.read(staffAttendanceProvider.notifier).markAttendance(
              staffId: widget.staff.id,
              date: _dateStr,
              status: status,
            );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ??
            'تم تسجيل ${status == 'present' ? 'الحضور' : 'الغياب'} بنجاح'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (error == null) _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(staffAttendanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('حضور: ${widget.staff.fullName}'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'QR المدرب',
            icon: const Icon(Icons.qr_code_2),
            onPressed: _showQr,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            DateFormat('dd/MM/yyyy', 'ar')
                                .format(_selectedDate),
                            style: TextStyle(fontSize: 14.sp)),
                        Icon(Icons.calendar_today_outlined,
                            color: AppColors.grey400, size: 18.r),
                      ],
                    ),
                  ),
                ),
                Gap(16.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isSubmitting ? null : () => _mark('present'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success),
                        icon: const Icon(Icons.check),
                        label: const Text('حضور'),
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _mark('absent'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        icon: const Icon(Icons.close),
                        label: const Text('غياب'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'الشهر السابق',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shiftMonth(-1),
              ),
              Text(DateFormat('MMMM yyyy', 'ar').format(_month),
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
              IconButton(
                tooltip: 'الشهر التالي',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('حدث خطأ: $err')),
              data: (records) {
                final days = _buildDays(records);
                if (days.isEmpty) {
                  return const Center(
                      child: Text('لا يوجد سجل حضور هذا الشهر'));
                }
                final present =
                    days.where((d) => d.record?.status == 'present').length;
                final absent = days.length - present;
                final minutes = days.fold<int>(
                    0, (sum, d) => sum + (d.record?.minutesWorked ?? 0));
                return ListView.separated(
                  padding: EdgeInsets.all(12.r),
                  itemCount: days.length + 1,
                  separatorBuilder: (_, __) => Gap(6.h),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Text(
                        'حضور $present • غياب $absent • ساعات ${(minutes / 60).toStringAsFixed(1)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey700),
                      );
                    }
                    final d = days[i - 1];
                    final r = d.record;
                    final isPresent = r?.status == 'present';
                    final worked = r?.minutesWorked;
                    final times = [
                      if (r?.checkIn != null) 'حضور ${r!.checkIn}',
                      if (r?.checkOut != null) 'انصراف ${r!.checkOut}',
                      if (worked != null)
                        '${(worked / 60).toStringAsFixed(1)} ساعة',
                    ].join(' • ');
                    return ListTile(
                      tileColor:
                          isPresent ? AppColors.surface : AppColors.errorLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      leading: Icon(
                        isPresent ? Icons.check_circle : Icons.cancel,
                        color: isPresent ? AppColors.success : AppColors.error,
                      ),
                      title: Text(
                          '${_weekdayAr[d.date.weekday]} • ${DateFormat('dd/MM/yyyy').format(d.date)}'),
                      subtitle: times.isNotEmpty
                          ? Text(times)
                          : (r == null ? const Text('لم يُسجَّل حضور') : null),
                      trailing: Text(isPresent ? 'حضور' : 'غياب',
                          style: TextStyle(
                              color: isPresent
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
