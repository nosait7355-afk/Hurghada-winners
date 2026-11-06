import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/features/evaluation/presentation/providers/evaluation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class AddEvaluationScreen extends ConsumerStatefulWidget {
  final String playerId;
  final String academyId;
  final String playerName;

  const AddEvaluationScreen({
    super.key,
    required this.playerId,
    required this.academyId,
    required this.playerName,
  });

  @override
  ConsumerState<AddEvaluationScreen> createState() =>
      _AddEvaluationScreenState();
}

class _AddEvaluationScreenState extends ConsumerState<AddEvaluationScreen> {
  final _notesController = TextEditingController();
  DateTime _evaluationDate = DateTime.now();
  double _fitness = 5;
  double _basicSkills = 5;
  double _attack = 5;
  double _defense = 5;
  double _commitment = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _average =>
      (_fitness + _basicSkills + _attack + _defense + _commitment) / 5;

  String get _gradeLabel {
    if (_average >= 8) return 'ممتاز';
    if (_average >= 6) return 'جيد';
    return 'يحتاج تحسين';
  }

  Color get _gradeColor {
    if (_average >= 8) return AppColors.success;
    if (_average >= 6) return AppColors.warning;
    return AppColors.error;
  }

  Color get _gradeBgColor {
    if (_average >= 8) return AppColors.successLight;
    if (_average >= 6) return AppColors.warningLight;
    return AppColors.errorLight;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _evaluationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _evaluationDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final error = await ref
        .read(playerEvaluationsProvider.notifier)
        .createEvaluation(
          playerId: widget.playerId,
          fitness: _fitness,
          basicSkills: _basicSkills,
          attack: _attack,
          defense: _defense,
          commitment: _commitment,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          academyId: widget.academyId,
          evaluationDate: _evaluationDate,
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
          content: Text(AppStrings.evaluationAdded),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.addEvaluation),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Player name chip
            if (widget.playerName.isNotEmpty)
              Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline,
                          size: 16.sp, color: AppColors.primary),
                      Gap(6.w),
                      Text(
                        widget.playerName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Gap(20.h),

            // Date picker row
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.calendar_today,
                            color: AppColors.primary, size: 20.sp),
                      ),
                      Gap(12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.evaluationDate,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                            Gap(2.h),
                            Text(
                              dateFormat.format(_evaluationDate),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down,
                          color: AppColors.grey400, size: 24.sp),
                    ],
                  ),
                ),
              ),
            ),

            Gap(16.h),

            // Score sliders card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'درجات التقييم',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                    Gap(12.h),
                    _SliderRow(
                      label: AppStrings.fitnessScore,
                      value: _fitness,
                      onChanged: (v) => setState(() => _fitness = v),
                    ),
                    _SliderRow(
                      label: AppStrings.basicSkillsScore,
                      value: _basicSkills,
                      onChanged: (v) => setState(() => _basicSkills = v),
                    ),
                    _SliderRow(
                      label: AppStrings.attackScore,
                      value: _attack,
                      onChanged: (v) => setState(() => _attack = v),
                    ),
                    _SliderRow(
                      label: AppStrings.defenseScore,
                      value: _defense,
                      onChanged: (v) => setState(() => _defense = v),
                    ),
                    _SliderRow(
                      label: AppStrings.commitmentScore,
                      value: _commitment,
                      onChanged: (v) => setState(() => _commitment = v),
                    ),
                  ],
                ),
              ),
            ),

            Gap(16.h),

            // Live average display
            Card(
              color: AppColors.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.averageScore,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                        Gap(4.h),
                        Text(
                          _average.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: _gradeBgColor,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: _gradeColor, width: 1),
                      ),
                      child: Text(
                        _gradeLabel,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: _gradeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Gap(16.h),

            // Notes field
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppStrings.notes,
                hintText: 'ملاحظات اختيارية...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),

            Gap(24.h),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      AppStrings.addEvaluation,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),

            Gap(40.h),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
            Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.grey200,
        ),
        Gap(4.h),
      ],
    );
  }
}
