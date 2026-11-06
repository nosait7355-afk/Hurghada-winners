import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:hurghada_winners/features/reports/services/excel_report_service.dart';
import 'package:hurghada_winners/features/reports/services/pdf_report_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:printing/printing.dart';

class PayrollReportScreen extends ConsumerStatefulWidget {
  final String month;
  /// أكاديمية super_admin التي يتصرف كها (يتجاهلها الخادم لباقي الأدوار).
  final String academyId;
  const PayrollReportScreen({super.key, required this.month, required this.academyId});

  @override
  ConsumerState<PayrollReportScreen> createState() => _PayrollReportScreenState();
}

class _PayrollReportScreenState extends ConsumerState<PayrollReportScreen> {
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref
        .read(payrollReportProvider.notifier)
        .load(widget.month, academyId: widget.academyId));
  }

  Future<void> _exportPdf() async {
    final data = ref.read(payrollReportProvider).valueOrNull;
    if (data == null) return;
    setState(() => _exporting = true);
    try {
      final bytes = await PdfReportService.generatePayrollReport(
        rows: data.report
            .map((r) => (fullName: r.fullName, position: r.position, baseSalary: r.baseSalary, deductionAmount: r.deductionAmount, netSalary: r.netSalary, status: r.status))
            .toList(),
        academyName: '',
        monthLabel: widget.month,
        currencyLabel: '',
      );
      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: 'payroll_report_${widget.month}.pdf');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportExcel() async {
    final data = ref.read(payrollReportProvider).valueOrNull;
    if (data == null) return;
    setState(() => _exporting = true);
    try {
      final bytes = await ExcelReportService.generatePayrollExcel(
        data.report
            .map((r) => (fullName: r.fullName, position: r.position, baseSalary: r.baseSalary, deductionAmount: r.deductionAmount, netSalary: r.netSalary, status: r.status))
            .toList(),
      );
      if (!mounted) return;
      await ExcelReportService.shareExcel(bytes, 'payroll_report_${widget.month}.xlsx');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(payrollReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('تقرير الرواتب — ${widget.month}'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('حدث خطأ: $err')),
              data: (data) {
                if (data.report.isEmpty) return const Center(child: Text('لا توجد رواتب لهذا الشهر'));
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12.r)),
                        child: Column(
                          children: [
                            _totalRow('إجمالي الرواتب الأساسية', data.totalBaseSalary),
                            _totalRow('إجمالي الخصومات', data.totalDeductions),
                            _totalRow('إجمالي صافي الرواتب', data.totalNetSalary, bold: true),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 12.r),
                        itemCount: data.report.length,
                        separatorBuilder: (_, __) => Gap(6.h),
                        itemBuilder: (_, i) {
                          final r = data.report[i];
                          return ListTile(
                            tileColor: AppColors.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            title: Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(r.position),
                            trailing: Text(r.netSalary.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                          );
                        },
                      ),
                    ),
                  ],
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

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.sp)),
          Text(value.toStringAsFixed(0), style: TextStyle(fontSize: bold ? 16.sp : 13.sp, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
