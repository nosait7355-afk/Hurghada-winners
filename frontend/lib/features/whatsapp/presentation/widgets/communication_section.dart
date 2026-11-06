import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/whatsapp/presentation/screens/custom_message_screen.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class CommunicationSection extends StatelessWidget {
  final PlayerEntity player;
  final String academyName;
  final SubscriptionEntity? latestSubscription;
  final EvaluationEntity? latestEvaluation;

  const CommunicationSection({
    super.key,
    required this.player,
    required this.academyName,
    this.latestSubscription,
    this.latestEvaluation,
  });

  Future<void> _launchPhone(
      BuildContext context, String phone, String message) async {
    final opened = await WhatsAppUtils.open(phone, message: message);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.whatsappNotInstalled),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _launch(BuildContext context, String message) =>
      _launchPhone(context, player.parentPhone, message);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: const Color(0xFF25D366),
                    size: 20.sp,
                  ),
                ),
                Gap(10.w),
                Text(
                  AppStrings.communication,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Gap(14.h),

            // 0. Contact Player directly (only when the player has a phone)
            if (player.playerPhone != null &&
                player.playerPhone!.isNotEmpty) ...[
              _ActionButton(
                icon: Icons.sports_tennis_outlined,
                label: AppStrings.contactPlayer,
                color: const Color(0xFF25D366),
                onTap: () => _launchPhone(
                  context,
                  player.playerPhone!,
                  'السلام عليكم ${player.fullName}،\n'
                      'أتواصل معك من $academyName 🏀',
                ),
              ),
              Gap(8.h),
            ],

            // 1. Contact Parent
            _ActionButton(
              icon: Icons.phone_in_talk_outlined,
              label: AppStrings.contactParent,
              color: AppColors.secondary,
              onTap: () => _launch(
                context,
                WhatsAppUtils.contactTemplate(
                  parentName: player.parentName,
                  playerName: player.fullName,
                  academyName: academyName,
                ),
              ),
            ),
            Gap(8.h),

            // 2. تذكير التجديد — رسالة واحدة تتكيّف (قبل/يوم/بعد الانتهاء)
            // وتحمل موعد التجديد وطريقة الدفع.
            _ActionButton(
              icon: Icons.notification_important_outlined,
              label: AppStrings.subscriptionReminder,
              color: (latestSubscription?.isActive ?? false)
                  ? AppColors.warning
                  : AppColors.error,
              onTap: () => _launch(
                context,
                WhatsAppUtils.renewalReminderTemplate(
                  parentName: player.parentName,
                  playerName: player.fullName,
                  academyName: academyName,
                  endDate: latestSubscription?.endDate,
                ),
              ),
            ),
            Gap(8.h),

            // 4. Evaluation Follow-up
            _ActionButton(
              icon: Icons.assessment_outlined,
              label: AppStrings.evaluationFollowUp,
              color: AppColors.primary,
              onTap: () {
                final avg = latestEvaluation != null
                    ? latestEvaluation!.average.toStringAsFixed(1)
                    : '---';
                final grade = latestEvaluation?.gradeLabel ?? '---';
                _launch(
                  context,
                  WhatsAppUtils.evaluationFollowUpTemplate(
                    parentName: player.parentName,
                    playerName: player.fullName,
                    average: avg,
                    grade: grade,
                    academyName: academyName,
                  ),
                );
              },
            ),
            Gap(8.h),

            // 5. Custom Message
            _ActionButton(
              icon: Icons.edit_note_outlined,
              label: AppStrings.customMessage,
              color: const Color(0xFF25D366),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomMessageScreen(
                    phone: player.parentPhone,
                    parentName: player.parentName,
                    playerName: player.fullName,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        alignment: AlignmentDirectional.centerStart,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp),
          Gap(10.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 14.sp, color: color.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
