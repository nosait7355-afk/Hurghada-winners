import 'dart:typed_data';

import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:hurghada_winners/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:hurghada_winners/features/attendance/services/attendance_pdf_service.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

/// تقرير الحضور والغياب — على أساس اشتراك كل لاعب (من بداية اشتراكه النشط
/// حتى نهايته)، لا على الشهر الميلادي.
class AttendanceReportScreen extends ConsumerStatefulWidget {
  final String academyId;
  const AttendanceReportScreen({super.key, required this.academyId});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  String _subscription = 'active'; // active | all
  String? _sport;
  String _search = ''; // محلي على الصفوف المحمّلة
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final academy =
        ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final academyName = academy?.name ?? 'الأكاديمية';
    final isMultiSport = academy?.isMultiSport ?? false;
    final sports = academy?.sports ?? const <String>[];

    final filter = AttendanceReportFilter(
      academyId: widget.academyId,
      sport: _sport,
      subscription: _subscription,
    );
    final reportAsync = ref.watch(attendanceReportProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقرير الحضور والغياب'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // توضيح أساس الحساب
          Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18.sp, color: AppColors.primary),
                Gap(8.w),
                Expanded(
                  child: Text(
                    'الحساب من بداية الاشتراك النشط لكل لاعب حتى نهايته',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey700),
                  ),
                ),
              ],
            ),
          ),
          // فلتر الاشتراك
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
            child: Row(
              children: [
                for (final (value, label) in const [
                  ('active', 'اشتراك نشط'),
                  ('all', 'الكل'),
                ]) ...[
                  Expanded(
                    child: ChoiceChip(
                      label: SizedBox(
                          width: double.infinity,
                          child: Text(label, textAlign: TextAlign.center)),
                      selected: _subscription == value,
                      onSelected: (_) => setState(() => _subscription = value),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _subscription == value
                            ? AppColors.white
                            : AppColors.grey700,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.white,
                    ),
                  ),
                  if (value == 'active') Gap(8.w),
                ],
              ],
            ),
          ),
          // بحث محلي بالاسم أو الكود
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.trim()),
              decoration: InputDecoration(
                hintText: 'بحث باسم اللاعب أو الكود',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.white,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          // فلتر الرياضة
          if (isMultiSport)
            SizedBox(
              height: 44.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                itemCount: sports.length + 1,
                separatorBuilder: (_, __) => Gap(8.w),
                itemBuilder: (_, i) {
                  final value = i == 0 ? null : sports[i - 1];
                  final isSel = value == _sport;
                  return ChoiceChip(
                    label: Text(value ?? 'الكل'),
                    selected: isSel,
                    onSelected: (_) => setState(() => _sport = value),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.white : AppColors.grey700,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: AppColors.white,
                  );
                },
              ),
            ),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 56.sp, color: AppColors.error),
                    Gap(12.h),
                    Text('تعذّر تحميل التقرير',
                        style: TextStyle(
                            fontSize: 14.sp, color: AppColors.grey700)),
                    Gap(12.h),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(attendanceReportProvider(filter)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (report) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(attendanceReportProvider(filter)),
                child: _ReportBody(
                  report: report,
                  search: _search,
                  academyId: widget.academyId,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: reportAsync.maybeWhen(
        data: (report) => FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          onPressed: _exporting
              ? null
              : () => _exportPdf(report, academyName, _sport),
          icon: _exporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('تصدير PDF'),
        ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _exportPdf(
      AttendanceReport report, String academyName, String? sport) async {
    setState(() => _exporting = true);
    try {
      final bytes = await AttendancePdfService.generate(
        report: report,
        academyName: academyName,
        sportLabel: sport,
      );
      if (!mounted) return;
      _showExportSheet(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر إنشاء التقرير: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showExportSheet(Uint8List bytes) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gap(12.h),
            ListTile(
              leading: const Icon(Icons.print_outlined,
                  color: AppColors.secondary),
              title: const Text('معاينة / طباعة'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.layoutPdf(onLayout: (_) async => bytes);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.share_outlined, color: AppColors.primary),
              title: const Text('مشاركة'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.sharePdf(
                    bytes: bytes, filename: 'attendance_report.pdf');
              },
            ),
            Gap(8.h),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final AttendanceReport report;
  final String search;
  final String academyId;
  const _ReportBody({
    required this.report,
    required this.search,
    required this.academyId,
  });

  @override
  Widget build(BuildContext context) {
    final q = search.toLowerCase();
    final rows = q.isEmpty
        ? report.rows
        : report.rows
            .where((r) =>
                r.fullName.toLowerCase().contains(q) ||
                r.playerCode.toLowerCase().contains(q))
            .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 88.h),
      children: [
        // بطاقات الملخص
        Row(
          children: [
            _SummaryCard(
                label: 'اللاعبون',
                value: '${report.playersCount}',
                color: AppColors.secondary),
            Gap(8.w),
            _SummaryCard(
                label: 'الحضور',
                value: '${report.totalPresent}',
                color: const Color(0xFF2D9748)),
          ],
        ),
        Gap(8.h),
        Row(
          children: [
            _SummaryCard(
                label: 'الغياب',
                value: '${report.totalAbsent}',
                color: AppColors.error),
            Gap(8.w),
            _SummaryCard(
                label: 'نسبة الالتزام',
                value: '${report.overallRate}%',
                color: AppColors.primary),
          ],
        ),
        Gap(16.h),
        if (rows.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Center(
              child: Text('لا توجد بيانات',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.grey500)),
            ),
          )
        else
          ...rows.map((r) => _RowTile(
                row: r,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PlayerDetailScreen(
                      playerId: r.playerId, academyId: academyId),
                )),
              )),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white)),
            Gap(2.h),
            Text(label,
                style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.white.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final AttendanceReportRow row;
  final VoidCallback onTap;
  const _RowTile({required this.row, required this.onTap});

  Color get _rateColor {
    if (row.rate >= 75) return const Color(0xFF2D9748);
    if (row.rate >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'ar');
    final active = row.isActive;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        elevation: 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // دائرة النسبة (نشط) أو علامة منتهي
                    Container(
                      width: 48.w,
                      height: 48.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (active ? _rateColor : AppColors.error)
                            .withValues(alpha: 0.12),
                      ),
                      child: active
                          ? Text(
                              '${row.rate}%',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: _rateColor,
                              ),
                            )
                          : Icon(Icons.block,
                              color: AppColors.error, size: 22.sp),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.fullName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey900,
                            ),
                          ),
                          Gap(2.h),
                          Text(
                            [
                              row.playerCode,
                              if (row.sport != null && row.sport!.isNotEmpty)
                                row.sport!,
                            ].join(' • '),
                            style: TextStyle(
                                fontSize: 11.sp, color: AppColors.grey500),
                          ),
                          if (active &&
                              row.subscriptionStart != null &&
                              row.subscriptionEnd != null) ...[
                            Gap(2.h),
                            Text(
                              'الاشتراك: ${fmt.format(row.subscriptionStart!)} ← ${fmt.format(row.subscriptionEnd!)}',
                              style: TextStyle(
                                  fontSize: 11.sp, color: AppColors.grey600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (active)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _miniStat(
                              'حضور', '${row.present}', const Color(0xFF2D9748)),
                          Gap(2.h),
                          _miniStat('غياب', '${row.absent}', AppColors.error),
                        ],
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text('منتهي',
                            style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error)),
                      ),
                  ],
                ),
                if (active && row.expectedTotal > 0) ...[
                  Gap(10.h),
                  _AttendanceDots(
                    total: row.expectedTotal,
                    filled: row.present.clamp(0, row.expectedTotal),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
        Text(value,
            style: TextStyle(
                fontSize: 12.sp, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

/// دائرة لكل يوم تدريب متوقع على كامل فترة الاشتراك — الممتلئة = الحضور.
class _AttendanceDots extends StatelessWidget {
  final int total;
  final int filled;
  const _AttendanceDots({required this.total, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4.w,
      runSpacing: 4.h,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? const Color(0xFF2D9748) : AppColors.white,
              border: Border.all(
                color: i < filled ? const Color(0xFF2D9748) : AppColors.grey300,
                width: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}
