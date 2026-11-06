import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/layout/desktop_grid.dart';
import 'package:hurghada_winners/core/layout/desktop_scaffold.dart';
import 'package:hurghada_winners/core/layout/responsive.dart';
import 'package:hurghada_winners/features/attendance/presentation/screens/attendance_log_screen.dart';
import 'package:hurghada_winners/features/attendance/presentation/screens/attendance_report_screen.dart';
import 'package:hurghada_winners/features/attendance/presentation/screens/attendance_scan_screen.dart';
import 'package:hurghada_winners/features/staff/presentation/screens/staff_scan_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class AttendanceHubScreen extends StatelessWidget {
  final String academyId;
  const AttendanceHubScreen({super.key, required this.academyId});

  List<_HubTileData> _tiles(BuildContext context) => [
        _HubTileData(
          icon: Icons.qr_code_scanner,
          color: AppColors.primary,
          title: 'مسح QR',
          subtitle: 'تسجيل حضور لاعب عبر مسح بطاقته',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AttendanceScanScreen(academyId: academyId),
            ),
          ),
        ),
        _HubTileData(
          icon: Icons.list_alt_outlined,
          color: AppColors.secondary,
          title: 'سجل الحضور',
          subtitle: 'عرض سجل الحضور مع الفلاتر',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AttendanceLogScreen(academyId: academyId),
            ),
          ),
        ),
        _HubTileData(
          icon: Icons.assessment_outlined,
          color: const Color(0xFF2D9748),
          title: 'تقرير الحضور والغياب',
          subtitle: 'إحصائيات الالتزام و PDF',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AttendanceReportScreen(academyId: academyId),
            ),
          ),
        ),
        _HubTileData(
          icon: Icons.badge_outlined,
          color: const Color(0xFF7B4BC4),
          title: 'حضور وانصراف المدربين',
          subtitle: 'مسح QR المدرب: حضور ثم انصراف + السجل',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StaffScanScreen(academyId: academyId),
            ),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final tier =
        kIsWeb ? screenTierOf(MediaQuery.sizeOf(context).width) : ScreenTier.mobile;

    if (tier != ScreenTier.mobile) {
      return DesktopScaffold(
        location: '/attendance-hub',
        tier: tier,
        title: 'الحضور والانصراف',
        content: DesktopGrid(
          isDesktop: tier == ScreenTier.desktop,
          desktopColumns: 3,
          childAspectRatio: 1.6,
          children:
              _tiles(context).map((t) => _DesktopHubTile(data: t)).toList(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الحضور والانصراف'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            for (final t in _tiles(context)) ...[
              _HubTile(data: t),
              Gap(14.h),
            ],
          ],
        ),
      ),
    );
  }
}

class _HubTileData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubTileData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _HubTile extends StatelessWidget {
  final _HubTileData data;
  const _HubTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(data.icon, color: data.color, size: 26.sp),
            ),
            Gap(14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey900,
                    ),
                  ),
                  Gap(4.h),
                  Text(
                    data.subtitle,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: AppColors.grey300, size: 22.sp),
          ],
        ),
      ),
    );
  }
}

// ─── Desktop/Tablet tile — smaller card inside DesktopGrid ──────────────────

class _DesktopHubTile extends StatelessWidget {
  final _HubTileData data;
  const _DesktopHubTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.grey500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
