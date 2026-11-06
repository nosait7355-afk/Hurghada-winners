import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/expenses/domain/entities/expense_entity.dart';
import 'package:hurghada_winners/features/expenses/domain/repositories/expense_repository.dart';
import 'package:hurghada_winners/features/expenses/presentation/providers/expense_provider.dart';
import 'package:hurghada_winners/features/reports/services/excel_report_service.dart';
import 'package:hurghada_winners/features/reports/services/pdf_report_service.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

enum _Period { today, thisWeek, thisMonth, custom }

class ExpenseReportScreen extends ConsumerStatefulWidget {
  /// أكاديمية super_admin التي يتصرف كها (يتجاهلها الخادم لباقي الأدوار).
  final String academyId;
  const ExpenseReportScreen({super.key, required this.academyId});

  @override
  ConsumerState<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends ConsumerState<ExpenseReportScreen> {
  _Period _period = _Period.thisMonth;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _applyPeriod(_Period period) {
    final now = DateTime.now();
    setState(() {
      _period = period;
      switch (period) {
        case _Period.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case _Period.thisWeek:
          _startDate = now.subtract(Duration(days: now.weekday % 7));
          _endDate = now;
          break;
        case _Period.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case _Period.custom:
          break;
      }
    });
    if (period != _Period.custom) _load();
  }

  void _load() {
    ref.read(expenseReportProvider.notifier).load(
          startDate: DateFormat('yyyy-MM-dd').format(_startDate),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate),
          academyId: widget.academyId,
        );
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _period = _Period.custom;
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _load();
    }
  }

  Future<List<ExpenseEntity>> _fetchRows() async {
    final repo = sl<ExpenseRepository>();
    final result = await repo.getExpenses(
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
      limit: 500,
      academyId: widget.academyId,
    );
    return result.fold((_) => [], (data) => data.expenses);
  }

  Future<void> _exportPdf() async {
    final data = ref.read(expenseReportProvider).valueOrNull;
    if (data == null) return;
    setState(() => _exporting = true);
    try {
      final rows = await _fetchRows();
      final bytes = await PdfReportService.generateExpenseReport(
        rows: rows.map((e) => (name: e.name, category: e.categoryLabel, amount: e.amount, date: e.date)).toList(),
        totalAmount: data.totalAmount,
        byCategory: data.byCategory.map((k, v) => MapEntry(expenseCategoryLabels[k] ?? k, v.total)),
        academyName: '',
        dateRangeLabel: '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
        currencyLabel: '',
      );
      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: 'expense_report.pdf');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final rows = await _fetchRows();
      final bytes = await ExcelReportService.generateExpenseExcel(
        rows.map((e) => (name: e.name, category: e.categoryLabel, amount: e.amount, date: e.date)).toList(),
      );
      if (!mounted) return;
      await ExcelReportService.shareExcel(bytes, 'expense_report.xlsx');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(expenseReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تقرير المصروفات'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                ChoiceChip(label: const Text('اليوم'), selected: _period == _Period.today, onSelected: (_) => _applyPeriod(_Period.today)),
                ChoiceChip(label: const Text('هذا الأسبوع'), selected: _period == _Period.thisWeek, onSelected: (_) => _applyPeriod(_Period.thisWeek)),
                ChoiceChip(label: const Text('هذا الشهر'), selected: _period == _Period.thisMonth, onSelected: (_) => _applyPeriod(_Period.thisMonth)),
                ActionChip(
                  label: Text(_period == _Period.custom
                      ? '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}'
                      : 'فترة مخصصة'),
                  avatar: const Icon(Icons.date_range_outlined, size: 18),
                  onPressed: _pickCustomRange,
                ),
              ],
            ),
          ),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('حدث خطأ: $err')),
              data: (data) {
                if (data == null) return const SizedBox.shrink();
                return ListView(
                  padding: EdgeInsets.all(16.r),
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(12.r)),
                      child: Column(
                        children: [
                          Text('إجمالي المصروفات', style: TextStyle(fontSize: 13.sp, color: AppColors.grey700)),
                          Gap(4.h),
                          Text(data.totalAmount.toStringAsFixed(0), style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w800, color: AppColors.error)),
                          Gap(4.h),
                          Text('${data.totalCount} عملية', style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
                        ],
                      ),
                    ),
                    Gap(16.h),
                    Text('حسب التصنيف', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                    Gap(8.h),
                    ...data.byCategory.entries.map((e) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(expenseCategoryLabels[e.key] ?? e.key, style: TextStyle(fontSize: 13.sp)),
                              Text('${e.value.total.toStringAsFixed(0)} (${e.value.count})', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
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
}
