import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شارة نوع الحضور — لا تظهر للحضور العادي.
class AttendanceKindBadge extends StatelessWidget {
  final AttendanceKind kind;
  const AttendanceKindBadge({super.key, required this.kind});

  static (String, Color, IconData)? styleOf(AttendanceKind kind) =>
      switch (kind) {
        AttendanceKind.payLater =>
          ('دفع لاحقاً', AppColors.warning, Icons.schedule),
        AttendanceKind.makeup =>
          ('تعويض غياب', AppColors.secondary, Icons.event_repeat),
        AttendanceKind.free =>
          ('حصة مجانية', const Color(0xFF2D9748), Icons.card_giftcard),
        AttendanceKind.regular => null,
      };

  @override
  Widget build(BuildContext context) {
    final style = styleOf(kind);
    if (style == null) return const SizedBox.shrink();
    final (label, color, icon) = style;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 4.w),
          Text(label,
              style: TextStyle(
                  fontSize: 11.sp, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
