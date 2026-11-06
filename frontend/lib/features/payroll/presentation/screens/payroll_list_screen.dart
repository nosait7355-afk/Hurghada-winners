import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:hurghada_winners/features/payroll/presentation/screens/payroll_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class PayrollListScreen extends ConsumerStatefulWidget {
  final String academyId;
  const PayrollListScreen({super.key, required this.academyId});

  @override
  ConsumerState<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends ConsumerState<PayrollListScreen> {
  String _month = DateFormat('yyyy-MM').format(DateTime.now());
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(payrollProvider.notifier).load(_month, academyId: widget.academyId));
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final current = DateTime.parse('$_month-01');
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _month = DateFormat('yyyy-MM').format(picked));
      ref.read(payrollProvider.notifier).load(_month, academyId: widget.academyId);
    }
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    final error = await ref
        .read(payrollProvider.notifier)
        .generate(_month, academyId: widget.academyId);
    if (!mounted) return;
    setState(() => _isGenerating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم توليد الرواتب بنجاح'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markPaid(String id) async {
    final error = await ref.read(payrollProvider.notifier).markPaid(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم تأكيد دفع الراتب'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payrollAsync = ref.watch(payrollProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الرواتب'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'تقرير الرواتب',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => PayrollReportScreen(
                        month: _month,
                        academyId: widget.academyId,
                      )),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickMonth,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_month),
                  ),
                ),
                Gap(12.w),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generate,
                  icon: _isGenerating
                      ? SizedBox(height: 16.h, width: 16.h, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Icon(Icons.calculate_outlined),
                  label: const Text('توليد الرواتب'),
                ),
              ],
            ),
          ),
          Expanded(
            child: payrollAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('حدث خطأ: $err')),
              data: (state) {
                if (state.records.isEmpty) {
                  return const Center(child: Text('لا توجد رواتب لهذا الشهر — اضغط "توليد الرواتب"'));
                }
                return ListView.separated(
                  padding: EdgeInsets.all(12.r),
                  itemCount: state.records.length,
                  separatorBuilder: (_, __) => Gap(8.h),
                  itemBuilder: (_, i) {
                    final p = state.records[i];
                    final isPaid = p.status == 'paid';
                    return Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12.r)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.staffName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp)),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: isPaid ? AppColors.successLight : AppColors.warningLight,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(isPaid ? 'مدفوع' : 'معلق', style: TextStyle(fontSize: 11.sp, color: isPaid ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          Gap(4.h),
                          Text(p.staffPosition, style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
                          Gap(8.h),
                          // سجلات النظام القديم (بلا سعر تمرينة) تُعرض كما حُسبت وقتها.
                          if (p.sessionRate > 0)
                            Text('سعر التمرينة ${p.sessionRate.toStringAsFixed(0)} × ${p.presentCount} يوم حضور', style: TextStyle(fontSize: 12.sp))
                          else ...[
                            Text('الراتب الأساسي: ${p.baseSalary.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp)),
                            Text('الغياب: ${p.absentCount} يوم • الخصم: ${p.deductionAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp)),
                          ],
                          Text('صافي الراتب: ${p.netSalary.toStringAsFixed(0)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.success)),
                          if (!isPaid) ...[
                            Gap(8.h),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _markPaid(p.id),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('تأكيد الدفع'),
                              ),
                            ),
                          ],
                        ],
                      ),
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
