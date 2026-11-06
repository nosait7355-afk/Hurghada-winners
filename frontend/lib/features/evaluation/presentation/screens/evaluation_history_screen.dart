import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/evaluation/presentation/providers/evaluation_provider.dart';
import 'package:hurghada_winners/features/evaluation/presentation/screens/add_evaluation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class EvaluationHistoryScreen extends ConsumerStatefulWidget {
  final String playerId;
  final String academyId;
  final String playerName;

  const EvaluationHistoryScreen({
    super.key,
    required this.playerId,
    required this.academyId,
    required this.playerName,
  });

  @override
  ConsumerState<EvaluationHistoryScreen> createState() =>
      _EvaluationHistoryScreenState();
}

class _EvaluationHistoryScreenState
    extends ConsumerState<EvaluationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(playerEvaluationsProvider.notifier)
          .setPlayer(widget.playerId);
    });
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String evaluationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('حذف التقييم'),
        content: const Text(AppStrings.deleteEvaluationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final error = await ref
        .read(playerEvaluationsProvider.notifier)
        .deleteEvaluation(evaluationId);

    if (!context.mounted) return;

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
          content: Text(AppStrings.evaluationDeleted),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final evaluationsAsync = ref.watch(playerEvaluationsProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;
    final isAcademyLevelSame =
        !isSuperAdmin && authState?.user?.academyId == widget.academyId;
    final canEdit = isSuperAdmin || isAcademyLevelSame;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.evaluationHistory),
            if (widget.playerName.isNotEmpty)
              Text(
                widget.playerName,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey500,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEvaluationScreen(
                    playerId: widget.playerId,
                    academyId: widget.academyId,
                    playerName: widget.playerName,
                  ),
                ),
              ),
              icon: const Icon(Icons.add_chart),
              label: const Text(AppStrings.addEvaluation),
            )
          : null,
      body: evaluationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
                Gap(16.h),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                Gap(16.h),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(playerEvaluationsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          if (state.evaluations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment_outlined,
                      size: 80.sp, color: AppColors.grey300),
                  Gap(16.h),
                  Text(
                    AppStrings.noEvaluations,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(playerEvaluationsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
              itemCount: state.evaluations.length,
              itemBuilder: (context, index) {
                final evaluation = state.evaluations[index];
                return _EvaluationCard(
                  evaluation: evaluation,
                  canEdit: canEdit,
                  onDelete: () =>
                      _confirmDelete(context, ref, evaluation.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  final EvaluationEntity evaluation;
  final bool canEdit;
  final VoidCallback onDelete;

  const _EvaluationCard({
    required this.evaluation,
    required this.canEdit,
    required this.onDelete,
  });

  Color _gradeColor() {
    if (evaluation.average >= 8) return AppColors.success;
    if (evaluation.average >= 6) return AppColors.warning;
    return AppColors.error;
  }

  Color _gradeBgColor() {
    if (evaluation.average >= 8) return AppColors.successLight;
    if (evaluation.average >= 6) return AppColors.warningLight;
    return AppColors.errorLight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');

    return GestureDetector(
      onLongPress: canEdit ? onDelete : null,
      child: Card(
        margin: EdgeInsets.only(bottom: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: date + grade chip
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16.sp, color: AppColors.grey500),
                  Gap(6.w),
                  Text(
                    dateFormat.format(evaluation.evaluationDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _gradeBgColor(),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      evaluation.gradeLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: _gradeColor(),
                      ),
                    ),
                  ),
                ],
              ),
              Gap(12.h),
              // Large average
              Center(
                child: Text(
                  evaluation.average.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Center(
                child: Text(
                  AppStrings.averageScore,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
              ),
              Gap(12.h),
              const Divider(height: 1, color: AppColors.grey100),
              Gap(8.h),
              // Score rows
              _ScoreRow(
                  label: AppStrings.fitnessScore, value: evaluation.fitness),
              _ScoreRow(
                  label: AppStrings.basicSkillsScore,
                  value: evaluation.basicSkills),
              _ScoreRow(
                  label: AppStrings.attackScore, value: evaluation.attack),
              _ScoreRow(
                  label: AppStrings.defenseScore, value: evaluation.defense),
              _ScoreRow(
                  label: AppStrings.commitmentScore,
                  value: evaluation.commitment),
              // Evaluator
              if (evaluation.evaluatorName != null &&
                  evaluation.evaluatorName!.isNotEmpty) ...[
                Gap(8.h),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14.sp, color: AppColors.grey500),
                    Gap(4.w),
                    Text(
                      '${AppStrings.evaluator}: ${evaluation.evaluatorName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
              // Notes
              if (evaluation.notes != null &&
                  evaluation.notes!.isNotEmpty) ...[
                Gap(8.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    evaluation.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (canEdit) ...[
                Gap(8.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'اضغط مطولاً للحذف',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.grey400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ),
          Text(
            '${value.toInt()}/10',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
