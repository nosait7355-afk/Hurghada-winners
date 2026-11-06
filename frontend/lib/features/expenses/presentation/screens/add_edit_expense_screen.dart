import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/expenses/domain/entities/expense_entity.dart';
import 'package:hurghada_winners/features/expenses/presentation/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseEntity? expense;
  const AddEditExpenseScreen({super.key, this.expense});

  bool get isEdit => expense != null;

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.expense?.name);
  late final _descriptionController = TextEditingController(text: widget.expense?.description);
  late final _amountController = TextEditingController(text: widget.expense?.amount.toStringAsFixed(0));

  DateTime _date = DateTime.now();
  String _category = expenseCategories.first;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _date = DateTime.parse(widget.expense!.date);
      _category = widget.expense!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

    String? error;
    if (widget.isEdit) {
      error = await ref.read(expensesProvider.notifier).updateExpense(
            id: widget.expense!.id,
            name: _nameController.text.trim(),
            description: description,
            amount: amount,
            date: dateStr,
            category: _category,
          );
    } else {
      error = await ref.read(expensesProvider.notifier).createExpense(
            name: _nameController.text.trim(),
            description: description,
            amount: amount,
            date: dateStr,
            category: _category,
          );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEdit ? 'تم تحديث المصروف' : 'تم إضافة المصروف'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.isEdit ? 'تعديل المصروف' : 'إضافة مصروف'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('اسم المصروف'),
              Gap(6.h),
              TextFormField(
                controller: _nameController,
                decoration: _decoration(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المصروف مطلوب' : null,
              ),
              Gap(16.h),

              _label('الوصف (اختياري)'),
              Gap(6.h),
              TextFormField(controller: _descriptionController, maxLines: 3, decoration: _decoration()),
              Gap(16.h),

              _label('المبلغ'),
              Gap(6.h),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _decoration(),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  return (value == null || value < 0) ? 'المبلغ غير صحيح' : null;
                },
              ),
              Gap(16.h),

              _label('التاريخ'),
              Gap(6.h),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    key: ValueKey(_date),
                    initialValue: DateFormat('dd/MM/yyyy', 'ar').format(_date),
                    decoration: _decoration(suffixIcon: Icons.calendar_today_outlined),
                  ),
                ),
              ),
              Gap(16.h),

              _label('التصنيف'),
              Gap(6.h),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _decoration(),
                items: expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(expenseCategoryLabels[c]!))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              Gap(24.h),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))),
                child: _isLoading
                    ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(widget.isEdit ? 'حفظ التعديلات' : 'إضافة المصروف', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
              ),
              Gap(40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.grey700));

  InputDecoration _decoration({IconData? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.white,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: AppColors.grey400) : null,
      contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.grey200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.grey200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
