import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/reports/services/excel_report_service.dart';
import 'package:hurghada_winners/features/reports/services/pdf_report_service.dart';
import 'package:hurghada_winners/features/staff/presentation/providers/staff_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class StaffAttendanceReportScreen extends ConsumerStatefulWidget {
  final String academyId;
  const StaffAttendanceReportScreen({super.key, required this.academyId});

  @override
  ConsumerState<StaffAttendanceReportScreen> createState() =>
      _StaffAttendanceReportScreenState();
}

class _StaffAttendanceReportScreenState
    extends ConsumerState<StaffAttendanceReportScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    ref.read(staffAttendanceReportProvider.notifier).loadReport(
          startDate: DateFormat('yyyy-MM-dd').format(_startDate),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate),
          academyId: widget.academyId,
        );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _load();
    }
  }

  Future<void> _exportPdf() async {
    final rows = ref.read(staffAttendanceReportProvider).valueOrNull ?? [];
    setState(() => _exporting = true);
    try {
      final bytes = await PdfReportService.generateStaffAttendanceReport(
        rows: rows
            .map((r) => (
                  fullName: r.fullName,
                  position: r.position,
                  presentCount: r.presentCount,
                  absentCount: r.absentCount
                ))
            .toList(),
        academyName: '',
        dateRangeLabel:
            '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
      );
      if (!mounted) return;
      await Printing.sharePdf(
          bytes: bytes, filename: 'staff_attendance_report.pdf');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportExcel() async {
    final rows = ref.read(staffAttendanceReportProvider).valueOrNull ?? [];
    setState(() => _exporting = true);
    try {
      final bytes = await ExcelReportService.generateStaffAttendanceExcel(
        rows
            .map((r) => (
                  fullName: r.fullName,
                  position: r.position,
                  presentCount: r.presentCount,
                  absentCount: r.absentCount
                ))
            .toList(),
      );
      if (!mounted) return;
      await ExcelReportService.shareExcel(
          bytes, 'staff_attendance_report.xlsx');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(staffAttendanceReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppBar(title: const Text('تقرير حضور الموظفين'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                        '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('حدث خطأ: $err')),
              data: (rows) {
                if (rows.isEmpty)
                  return const Center(
                      child: Text('لا توجد بيانات لهذه الفترة'));
                return ListView.separated(
                  padding: EdgeInsets.all(12.r),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => Gap(6.h),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    return Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10.r)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.fullName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.sp)),
                                Text(r.position,
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.grey500)),
                              ],
                            ),
                          ),
                          Text('حضور: ${r.presentCount}',
                              style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                          Gap(12.w),
                          Text('غياب: ${r.absentCount}',
                              style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF'),
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportExcel,
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('Excel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
