import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// حضور/غياب اللاعب في اشتراكه: الحالة، الفترة، وصندوقا حضور وغياب.
///  • none    ⇒ إطار أحمر + "منتهي" + "لا يوجد اشتراك مسجّل".
///  • active  ⇒ إطار أخضر "منذ بداية الاشتراك الحالي" (برتقالي إن قارب على الانتهاء).
///  • expired ⇒ إطار أحمر + "منتهي" "في الاشتراك السابق".
class SubscriptionStatsBanner extends StatelessWidget {
  final AttendanceSubscriptionStats stats;
  final bool compact;

  const SubscriptionStatsBanner({
    super.key,
    required this.stats,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'ar');
    final Color color;
    final String caption;
    String? badge;
    if (stats.isNone) {
      color = AppColors.error;
      caption = 'لا يوجد اشتراك مسجّل لهذا اللاعب';
      badge = 'منتهي';
    } else if (stats.isActive) {
      final days = stats.daysRemaining ?? 0;
      color = stats.isExpiringSoon ? AppColors.warning : AppColors.success;
      caption = 'منذ بداية الاشتراك الحالي';
      if (stats.isExpiringSoon) {
        badge = 'قرب على الانتهاء — باقي $days ${days == 1 ? 'يوم' : days == 2 ? 'يومين' : 'أيام'}';
      } else {
        badge = 'نشط';
      }
    } else {
      color = AppColors.error;
      caption = 'في الاشتراك السابق';
      badge = 'منتهي';
    }

    final pad = compact ? 10.r : 14.r;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.card_membership, size: 18.sp, color: color),
              Gap(6.w),
              Expanded(
                child: Text(caption,
                    style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
            ],
          ),
          if (stats.startDate != null && stats.endDate != null) ...[
            Gap(4.h),
            Text(
              '${fmt.format(stats.startDate!)} ← ${fmt.format(stats.endDate!)}',
              style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey600),
            ),
          ],
          if (!stats.isNone) ...[
            Gap(compact ? 8.h : 10.h),
            Row(
              children: [
                _box('حضور', stats.present, AppColors.success),
                Gap(8.w),
                _box('غياب', stats.absent, AppColors.error),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _box(String label, int value, Color color) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 6.h : 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: compact ? 16.sp : 20.sp,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey700)),
            ],
          ),
        ),
      );
}
