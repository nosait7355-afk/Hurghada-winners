import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/currency_provider.dart';
import 'package:hurghada_winners/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class RenewSubscriptionScreen extends ConsumerStatefulWidget {
  final String playerId;
  final String academyId;
  final String playerName;

  const RenewSubscriptionScreen({
    super.key,
    required this.playerId,
    required this.academyId,
    required this.playerName,
  });

  @override
  ConsumerState<RenewSubscriptionScreen> createState() =>
      _RenewSubscriptionScreenState();
}

class _RenewSubscriptionScreenState
    extends ConsumerState<RenewSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate =
      DateTime.now().add(const Duration(days: 30));

  bool _isLoading = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'ar');

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate)
          ? _endDate
          : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await ref
        .read(playerSubscriptionsProvider(widget.playerId).notifier)
        .createSubscription(
          playerId: widget.playerId,
          type: 'RENEWAL',
          amount: double.parse(_amountController.text.trim()),
          startDate: _startDate,
          endDate: _endDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          academyId: widget.academyId,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.subscriptionRenewed),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // true = تم التجديد فعلاً (تستخدمه شاشة طلبات التجديد لاعتماد الطلب).
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyLabel =
        ref.watch(academyCurrencyLabelProvider(widget.academyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.renewSubscription),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Player name chip
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        color: AppColors.secondary, size: 20.sp),
                    Gap(8.w),
                    Expanded(
                      child: Text(
                        widget.playerName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        AppStrings.renewal,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Gap(24.h),

              // Amount field
              Text(
                AppStrings.subscriptionAmount,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.grey700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(8.h),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'مثال: 500',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  suffixText: currencyLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.required;
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'الرجاء إدخال مبلغ صحيح';
                  }
                  return null;
                },
              ),
              Gap(20.h),

              // Start date
              Text(
                AppStrings.startDate,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.grey700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(8.h),
              GestureDetector(
                onTap: _pickStartDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(12.r),
                    color: AppColors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 20.sp, color: AppColors.secondary),
                      Gap(12.w),
                      Text(
                        _dateFormat.format(_startDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Gap(20.h),

              // End date
              Text(
                AppStrings.endDate,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.grey700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(8.h),
              GestureDetector(
                onTap: _pickEndDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(12.r),
                    color: AppColors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 20.sp, color: AppColors.secondary),
                      Gap(12.w),
                      Text(
                        _dateFormat.format(_endDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Gap(20.h),

              // Notes field
              Text(
                AppStrings.notes,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.grey700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(8.h),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'ملاحظات اختيارية...',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              Gap(32.h),

              // Submit button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  _isLoading ? AppStrings.loading : AppStrings.renewSubscription,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  minimumSize: Size(double.infinity, 52.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              Gap(24.h),
            ],
          ),
        ),
      ),
    );
  }
}
