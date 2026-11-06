import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/expenses/domain/entities/expense_entity.dart';
import 'package:hurghada_winners/features/expenses/presentation/providers/expense_provider.dart';
import 'package:hurghada_winners/features/expenses/presentation/screens/add_edit_expense_screen.dart';
import 'package:hurghada_winners/features/expenses/presentation/screens/expense_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class ExpensesListScreen extends ConsumerStatefulWidget {
  final String academyId;
  const ExpensesListScreen({super.key, required this.academyId});

  @override
  ConsumerState<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends ConsumerState<ExpensesListScreen> {
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => ref.read(expensesProvider.notifier).load(academyId: widget.academyId));
  }

  Future<void> _confirmDelete(ExpenseEntity expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المصروف'),
        content: Text('هل تريد حذف "${expense.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      final error = await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'تم حذف المصروف'), backgroundColor: error != null ? AppColors.error : AppColors.success, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المصروفات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'تقرير المصروفات',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExpenseReportScreen(academyId: widget.academyId))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              children: [
                _filterChip(null, 'الكل'),
                ...expenseCategories.map((c) => _filterChip(c, expenseCategoryLabels[c]!)),
              ],
            ),
          ),
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('حدث خطأ: $err')),
              data: (state) {
                if (state.expenses.isEmpty) return const Center(child: Text('لا توجد مصروفات'));
                return RefreshIndicator(
                  onRefresh: () => ref.read(expensesProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: EdgeInsets.all(12.r),
                    itemCount: state.expenses.length,
                    separatorBuilder: (_, __) => Gap(8.h),
                    itemBuilder: (_, i) {
                      final e = state.expenses[i];
                      return Container(
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12.r)),
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditExpenseScreen(expense: e))),
                          title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${e.categoryLabel} • ${e.date}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(e.amount.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: AppColors.grey400,
                                onPressed: () => _confirmDelete(e),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? category, String label) {
    final selected = _categoryFilter == category;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _categoryFilter = category);
          ref.read(expensesProvider.notifier).load(
                category: category,
                academyId: widget.academyId,
              );
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.grey700),
      ),
    );
  }
}
