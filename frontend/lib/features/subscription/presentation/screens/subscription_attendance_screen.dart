import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:hurghada_winners/features/attendance/presentation/providers/attendance_calendar_provider.dart';
import 'package:hurghada_winners/features/attendance/presentation/widgets/attendance_kind_badge.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// حضور وغياب اللاعب خلال فترة اشتراك واحد، مقسّم بالشهور. الغياب في أيام
/// تمرين اللاعب فقط، والتعويض/المجاني يظهر حضوراً مع شارة توضّح نوعه.
class SubscriptionAttendanceScreen extends ConsumerWidget {
  final String playerId;
  final String playerName;
  final SubscriptionEntity subscription;

  const SubscriptionAttendanceScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.subscription,
  });

  // تواريخ الاشتراك تُخزَّن كمنتصف ليل UTC — نقرؤها بنفس الصيغة.
  static String _ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d.toUtc());

  static String _fmt(String ymd) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(ymd));
    } catch (_) {
      return ymd;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (
      playerId: playerId,
      from: _ymd(subscription.startDate),
      to: _ymd(subscription.endDate),
    );
    final cal = ref.watch(attendanceRangeProvider(key));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(playerName.isEmpty ? 'حضور الاشتراك' : playerName),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'اشتراك ${_fmt(key.from)} — ${_fmt(key.to)}',
              style: const TextStyle(fontSize: 12, color: AppColors.white),
            ),
          ),
        ),
      ),
      body: cal.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تعذّر تحميل الحضور'),
              Gap(12.h),
              ElevatedButton(
                onPressed: () => ref.invalidate(attendanceRangeProvider(key)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (c) {
          if (c.days.isEmpty) {
            return Center(
              child: Text('لا توجد أيام تمرين في فترة هذا الاشتراك بعد',
                  style: TextStyle(color: AppColors.grey500, fontSize: 14.sp)),
            );
          }
          // الأيام تأتي الأحدث أولاً — نجمعها بالشهر بنفس الترتيب.
          final months = <String, List<AttendanceCalendarDay>>{};
          for (final d in c.days) {
            months.putIfAbsent(d.date.substring(0, 7), () => []).add(d);
          }
          final total = c.present + c.absent;
          final rate = total == 0 ? 0 : (c.present * 100 / total).round();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(attendanceRangeProvider(key)),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                _Summary(present: c.present, absent: c.absent, rate: rate),
                Gap(12.h),
                for (final e in months.entries)
                  _MonthSection(monthKey: e.key, days: e.value, fmt: _fmt),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int present;
  final int absent;
  final int rate;
  const _Summary(
      {required this.present, required this.absent, required this.rate});

  @override
  Widget build(BuildContext context) {
    Widget box(String label, String value, Color color) => Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style:
                        TextStyle(fontSize: 12.sp, color: AppColors.grey700)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        box('حضر', '$present', AppColors.success),
        Gap(8.w),
        box('غاب', '$absent', AppColors.error),
        Gap(8.w),
        box('نسبة الحضور', '$rate%', AppColors.primary),
      ],
    );
  }
}

/// شهر قابل للطي: العنوان فيه عدد الحضور والغياب، والأيام بداخله.
class _MonthSection extends StatelessWidget {
  final String monthKey; // YYYY-MM
  final List<AttendanceCalendarDay> days;
  final String Function(String) fmt;
  const _MonthSection(
      {required this.monthKey, required this.days, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final present = days.where((d) => d.present).length;
    final absent = days.length - present;
    String title;
    try {
      title = DateFormat('MMMM yyyy', 'ar').format(DateTime.parse('$monthKey-01'));
    } catch (_) {
      title = monthKey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
        subtitle: Text('حضر $present • غاب $absent',
            style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
        childrenPadding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
        children: [
          for (final d in days) ...[
            _DayRow(day: d, dateText: fmt(d.date)),
            Gap(6.h),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final AttendanceCalendarDay day;
  final String dateText;
  const _DayRow({required this.day, required this.dateText});

  @override
  Widget build(BuildContext context) {
    final color = day.present ? AppColors.success : AppColors.error;
    final kind = AttendanceKind.fromApi(day.kind);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: day.present ? AppColors.background : AppColors.errorLight,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(day.present ? Icons.check_circle : Icons.cancel,
              color: color, size: 20.sp),
          Gap(8.w),
          Expanded(
            child: Text('${day.weekday} • $dateText',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
          ),
          if (day.present && kind != AttendanceKind.regular) ...[
            AttendanceKindBadge(kind: kind),
            Gap(6.w),
          ],
          Text(
            day.present
                ? (day.time.isNotEmpty ? 'حضر ${day.time}' : 'حضر')
                : 'غاب',
            style: TextStyle(
                fontSize: 12.sp, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
