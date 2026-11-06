import 'dart:async';

import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/usecases/delete_attendance_usecase.dart';
import 'package:hurghada_winners/features/attendance/presentation/providers/attendance_calendar_provider.dart';
import 'package:hurghada_winners/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:hurghada_winners/features/attendance/presentation/widgets/attendance_kind_badge.dart';
import 'package:hurghada_winners/features/attendance/presentation/widgets/subscription_stats_banner.dart';
import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

void _openPlayerPage(BuildContext context, String playerId, String academyId) {
  if (playerId.isEmpty) return;
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PlayerDetailScreen(playerId: playerId, academyId: academyId),
  ));
}

/// يُبطل كل ما يتأثر بتغيّر السجل (حذف/سحب للتحديث).
void _invalidateAttendance(WidgetRef ref) {
  ref
    ..invalidate(attendanceLogProvider)
    ..invalidate(attendanceReportProvider)
    ..invalidate(attendancePlayerSummaryProvider)
    ..invalidate(attendanceCalendarProvider);
}

class AttendanceLogScreen extends ConsumerStatefulWidget {
  final String academyId;
  const AttendanceLogScreen({super.key, required this.academyId});

  @override
  ConsumerState<AttendanceLogScreen> createState() =>
      _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends ConsumerState<AttendanceLogScreen> {
  String? _date; // 'YYYY-MM-DD' أو null = كل التواريخ
  String? _sport; // null = الكل

  // بحث لاعب على الخادم (اسم أو كود — الأرقام وحدها = الكود).
  String _search = '';
  Timer? _debounce;

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _search = v.trim());
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null) {
      setState(() =>
          _date = '${picked.year}-${_two(picked.month)}-${_two(picked.day)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final academy =
        ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    final sports = academy?.sports ?? const <String>[];
    final searching = _search.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سجل الحضور'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // فلتر التاريخ — يختفي أثناء البحث عن لاعب.
          if (!searching)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(_date ?? 'كل التواريخ'),
                    ),
                  ),
                  if (_date != null) ...[
                    Gap(8.w),
                    IconButton(
                      tooltip: 'مسح التاريخ',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _date = null),
                    ),
                  ],
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: TextField(
              onChanged: _onSearchChanged,
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
          // فلتر الرياضة (للأكاديميات متعددة الرياضات)
          if (isMultiSport)
            _SportChips(
              sports: sports,
              selected: _sport,
              onSelected: (s) => setState(() => _sport = s),
            ),
          Expanded(
            child: searching
                ? _PlayerSearchResults(
                    academyId: widget.academyId,
                    query: _search,
                    sport: _sport,
                  )
                : PagedAttendanceLog(
                    filter: AttendanceLogFilter(
                      academyId: widget.academyId,
                      date: _date,
                      sport: _sport,
                    ),
                    showDaySummary: _date != null,
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// قائمة سجلات مُصفّحة — "إظهار المزيد" يضيف صفحة (100 سجل).
// ---------------------------------------------------------------------------

class PagedAttendanceLog extends ConsumerStatefulWidget {
  final AttendanceLogFilter filter;

  /// يوم محدد: ملخص حضر/غاب + قائمة الغائبين (من الصفحة الأولى).
  final bool showDaySummary;

  /// عنصر يُعرض أعلى القائمة (مثل ملخص اللاعب).
  final Widget? header;

  const PagedAttendanceLog({
    super.key,
    required this.filter,
    this.showDaySummary = false,
    this.header,
  });

  @override
  ConsumerState<PagedAttendanceLog> createState() => _PagedAttendanceLogState();
}

class _PagedAttendanceLogState extends ConsumerState<PagedAttendanceLog> {
  int _pages = 1;

  @override
  void didUpdateWidget(covariant PagedAttendanceLog old) {
    super.didUpdateWidget(old);
    // تغيير الفلتر يعيد العدّاد للصفحة الأولى.
    if (old.filter != widget.filter) _pages = 1;
  }

  Future<void> _delete(AttendanceLogEntry e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف سجل الحضور'),
        content: Text(
            'حذف حضور "${e.playerName.isNotEmpty ? e.playerName : e.playerCode}" بتاريخ ${e.date}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await sl<DeleteAttendanceUsecase>()(e.id);
    result.fold(
      (f) => messenger.showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.error)),
      (_) {
        messenger.showSnackBar(const SnackBar(
            content: Text('تم حذف سجل الحضور'),
            backgroundColor: AppColors.success));
        _invalidateAttendance(ref);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authStateProvider).valueOrNull?.user?.role;
    final canDelete = role == UserRole.superAdmin ||
        role == UserRole.academyAdmin ||
        role == UserRole.admin;

    final pages = [
      for (var p = 1; p <= _pages; p++)
        ref.watch(attendanceLogProvider(widget.filter.copyWithPage(p))),
    ];
    final first = pages.first;

    if (first.isLoading && !first.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (first.hasError && !first.hasValue) {
      return _ErrorView(
        onRetry: () =>
            ref.invalidate(attendanceLogProvider(widget.filter.copyWithPage(1))),
      );
    }

    final firstData = first.value!;
    final records = <AttendanceLogEntry>[
      for (final page in pages)
        if (page.hasValue) ...page.value!.records,
    ];
    final last = pages.last;
    final total = firstData.total;
    final hasMore = last.hasValue && _pages < last.value!.totalPages;
    final absent = widget.showDaySummary
        ? firstData.absentPlayers
        : const <AttendancePlayer>[];
    final academyId = widget.filter.academyId;

    if (records.isEmpty && absent.isEmpty && widget.header == null) {
      return _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () async => _invalidateAttendance(ref),
      child: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          if (widget.header != null) ...[widget.header!, Gap(12.h)],
          if (widget.showDaySummary) ...[
            _DaySummary(present: total, absent: absent.length),
            Gap(12.h),
          ],
          if (records.isEmpty && widget.header != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text('لا توجد سجلات حضور',
                    style: TextStyle(color: AppColors.grey500, fontSize: 14.sp)),
              ),
            ),
          for (var i = 0; i < records.length; i++) ...[
            // كل التواريخ: عنوان لكل يوم (اسم اليوم + التاريخ + عدد الحضور).
            if (widget.filter.date == null &&
                widget.filter.playerId == null &&
                (i == 0 || records[i - 1].date != records[i].date))
              _DayHeader(
                date: records[i].date,
                count: records.where((x) => x.date == records[i].date).length,
              ),
            _LogTile(
              entry: records[i],
              onTap: () =>
                  _openPlayerPage(context, records[i].playerId, academyId),
              onDelete: canDelete ? () => _delete(records[i]) : null,
            ),
            Gap(10.h),
          ],
          if (records.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Center(
                child: Text('عرض ${records.length} من $total سجل',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
              ),
            ),
          if (last.isLoading && _pages > 1)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (last.hasError && _pages > 1)
            TextButton.icon(
              onPressed: () => ref.invalidate(
                  attendanceLogProvider(widget.filter.copyWithPage(_pages))),
              icon: const Icon(Icons.refresh),
              label: const Text('تعذّر التحميل — إعادة المحاولة'),
            )
          else if (hasMore)
            OutlinedButton.icon(
              onPressed: () => setState(() => _pages += 1),
              icon: const Icon(Icons.expand_more),
              label: const Text('إظهار المزيد'),
            ),
          if (absent.isNotEmpty) ...[
            Gap(12.h),
            Text('الغائبون (لهم تمرين في هذا اليوم)',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error)),
            Gap(8.h),
            for (final p in absent) ...[
              _AbsentTile(
                player: p,
                onTap: () => _openPlayerPage(context, p.id, academyId),
              ),
              Gap(8.h),
            ],
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// نتائج بحث اللاعب ⇒ صفحة سجل اللاعب
// ---------------------------------------------------------------------------

class _PlayerSearchResults extends ConsumerWidget {
  final String academyId;
  final String query;
  final String? sport;

  const _PlayerSearchResults({
    required this.academyId,
    required this.query,
    this.sport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = AttendancePlayerSearchKey(
        academyId: academyId, query: query, sport: sport);
    return ref.watch(attendancePlayerSearchProvider(key)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorView(
            onRetry: () => ref.invalidate(attendancePlayerSearchProvider(key)),
          ),
          data: (players) {
            if (players.isEmpty) {
              return Center(
                child: Text('لا يوجد لاعب مطابق',
                    style: TextStyle(color: AppColors.grey500, fontSize: 14.sp)),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.all(16.r),
              itemCount: players.length,
              separatorBuilder: (_, __) => Gap(8.h),
              itemBuilder: (_, i) {
                final p = players[i];
                final hasImage = p.imageUrl != null && p.imageUrl!.isNotEmpty;
                return Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      backgroundImage: hasImage
                          ? CachedNetworkImageProvider(p.imageUrl!)
                          : null,
                      child: hasImage
                          ? null
                          : const Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text(p.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([
                      p.playerCode,
                      if (p.sport != null && p.sport!.isNotEmpty) p.sport!,
                    ].join(' • ')),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AttendancePlayerLogScreen(
                        academyId: academyId,
                        player: p,
                      ),
                    )),
                  ),
                );
              },
            );
          },
        );
  }
}

/// سجل حضور لاعب واحد مع ملخص اشتراكه أعلاه.
class AttendancePlayerLogScreen extends ConsumerWidget {
  final String academyId;
  final AttendancePlayer player;

  const AttendancePlayerLogScreen({
    super.key,
    required this.academyId,
    required this.player,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(attendancePlayerSummaryProvider(player.id));
    final header = summary.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) => SubscriptionStatsBanner(stats: s.stats),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(player.fullName),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'صفحة اللاعب',
            icon: const Icon(Icons.person_outline),
            onPressed: () => _openPlayerPage(context, player.id, academyId),
          ),
        ],
      ),
      body: _PlayerCalendarView(playerId: player.id, header: header),
    );
  }
}

/// سجل اللاعب يوماً بيوم: حضر ✅ / غاب ❌ في أيام تدريبه، مجمّع بالشهر.
class _PlayerCalendarView extends ConsumerStatefulWidget {
  final String playerId;
  final Widget header;
  const _PlayerCalendarView({required this.playerId, required this.header});

  @override
  ConsumerState<_PlayerCalendarView> createState() =>
      _PlayerCalendarViewState();
}

class _PlayerCalendarViewState extends ConsumerState<_PlayerCalendarView> {
  static const _ranges = {30: 'شهر', 90: '3 شهور', 180: '6 شهور', 365: 'سنة'};
  int _range = 90;

  Future<void> _delete(AttendanceCalendarDay d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف سجل الحضور'),
        content: Text('حذف حضور يوم ${d.weekday} ${_fmt(d.date)}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || d.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await sl<DeleteAttendanceUsecase>()(d.id!);
    result.fold(
      (f) => messenger.showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.error)),
      (_) {
        messenger.showSnackBar(const SnackBar(
            content: Text('تم حذف سجل الحضور'),
            backgroundColor: AppColors.success));
        _invalidateAttendance(ref);
      },
    );
  }

  static String _fmt(String ymd) {
    try {
      return DateFormat('dd/MM/yyyy', 'ar').format(DateTime.parse(ymd));
    } catch (_) {
      return ymd;
    }
  }

  static String _monthOf(String ymd) {
    try {
      return DateFormat('MMMM yyyy', 'ar').format(DateTime.parse(ymd));
    } catch (_) {
      return ymd.length >= 7 ? ymd.substring(0, 7) : ymd;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authStateProvider).valueOrNull?.user?.role;
    final canDelete = role == UserRole.superAdmin ||
        role == UserRole.academyAdmin ||
        role == UserRole.admin;
    final key = AttendanceCalendarKey(widget.playerId, _range);
    final cal = ref.watch(attendanceCalendarProvider(key));

    final rangeChips = Wrap(
      spacing: 8.w,
      children: [
        for (final e in _ranges.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: _range == e.key,
            onSelected: (_) => setState(() => _range = e.key),
          ),
      ],
    );

    return RefreshIndicator(
      onRefresh: () async => _invalidateAttendance(ref),
      child: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          widget.header,
          Gap(12.h),
          rangeChips,
          Gap(12.h),
          ...cal.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (_, __) => [
              _ErrorView(
                  onRetry: () =>
                      ref.invalidate(attendanceCalendarProvider(key))),
            ],
            data: (c) {
              if (c.days.isEmpty) {
                return [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: Text('لا توجد أيام تدريب في هذه الفترة',
                          style: TextStyle(
                              color: AppColors.grey500, fontSize: 14.sp)),
                    ),
                  ),
                ];
              }
              final out = <Widget>[
                _DaySummary(present: c.present, absent: c.absent),
                Gap(12.h),
              ];
              String? month;
              for (final d in c.days) {
                final m = _monthOf(d.date);
                if (m != month) {
                  month = m;
                  out.add(Padding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 6.h),
                    child: Text(m,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.grey900)),
                  ));
                }
                out
                  ..add(_CalendarDayTile(
                    day: d,
                    dateText: _fmt(d.date),
                    onDelete: canDelete && d.present && d.id != null
                        ? () => _delete(d)
                        : null,
                  ))
                  ..add(Gap(8.h));
              }
              return out;
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  final AttendanceCalendarDay day;
  final String dateText;
  final VoidCallback? onDelete;
  const _CalendarDayTile(
      {required this.day, required this.dateText, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = day.present ? AppColors.success : AppColors.error;
    final kind = AttendanceKind.fromApi(day.kind);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: day.present ? AppColors.white : AppColors.errorLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(right: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(day.present ? Icons.check_circle : Icons.cancel,
              color: color, size: 22.sp),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${day.weekday} • $dateText',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900)),
                Gap(2.h),
                Text(
                  day.present
                      ? [
                          'حضر',
                          if (day.time.isNotEmpty) 'الساعة ${day.time}',
                          if (!day.scheduled) 'يوم إضافي',
                        ].join(' • ')
                      : 'غاب',
                  style: TextStyle(fontSize: 11.sp, color: color),
                ),
                if (day.present && kind != AttendanceKind.regular) ...[
                  Gap(4.h),
                  AttendanceKindBadge(kind: kind),
                ],
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'حذف',
              icon: Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20.sp),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// عناصر العرض
// ---------------------------------------------------------------------------

/// عنوان يوم في "كل التواريخ": اسم اليوم + التاريخ + عدد الحاضرين المعروضين.
class _DayHeader extends StatelessWidget {
  final String date;
  final int count;
  const _DayHeader({required this.date, required this.count});

  @override
  Widget build(BuildContext context) {
    String label;
    try {
      label = DateFormat('EEEE dd/MM/yyyy', 'ar').format(DateTime.parse(date));
    } catch (_) {
      label = date;
    }
    return Padding(
      padding: EdgeInsets.only(top: 6.h, bottom: 8.h),
      child: Row(
        children: [
          Icon(Icons.event, size: 18.sp, color: AppColors.primary),
          Gap(6.w),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text('حضر $count',
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}

class _SportChips extends StatelessWidget {
  final List<String> sports;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _SportChips({
    required this.sports,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...sports];
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        itemCount: options.length,
        separatorBuilder: (_, __) => Gap(8.w),
        itemBuilder: (_, i) {
          final value = options[i];
          final isSel = value == selected;
          return ChoiceChip(
            label: Text(value ?? 'الكل'),
            selected: isSel,
            onSelected: (_) => onSelected(value),
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
    );
  }
}

class _DaySummary extends StatelessWidget {
  final int present;
  final int absent;
  const _DaySummary({required this.present, required this.absent});

  @override
  Widget build(BuildContext context) {
    Widget box(String label, int value, Color color) => Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text('$value',
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey700)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        box('حضر', present, AppColors.success),
        Gap(10.w),
        box('غاب', absent, AppColors.error),
      ],
    );
  }
}

class _AbsentTile extends StatelessWidget {
  final AttendancePlayer player;
  final VoidCallback onTap;
  const _AbsentTile({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = player.imageUrl != null && player.imageUrl!.isNotEmpty;
    return Material(
      color: AppColors.errorLight,
      borderRadius: BorderRadius.circular(12.r),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        leading: CircleAvatar(
          backgroundColor: AppColors.white,
          backgroundImage:
              hasImage ? CachedNetworkImageProvider(player.imageUrl!) : null,
          child:
              hasImage ? null : const Icon(Icons.person, color: AppColors.error),
        ),
        title: Text(player.fullName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(player.playerCode),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AttendanceLogEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const _LogTile({required this.entry, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
              ),
              child: ClipOval(
                child: entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: entry.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(Icons.person,
                            color: AppColors.primary, size: 22.sp),
                      )
                    : Icon(Icons.person, color: AppColors.primary, size: 22.sp),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.playerName.isNotEmpty
                        ? entry.playerName
                        : entry.playerCode,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  Gap(2.h),
                  Text(
                    [
                      entry.playerCode,
                      if (entry.sport != null && entry.sport!.isNotEmpty)
                        entry.sport!,
                    ].join(' • '),
                    style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
                  ),
                  if (entry.kind != AttendanceKind.regular) ...[
                    Gap(4.h),
                    AttendanceKindBadge(kind: entry.kind),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtDate(entry.date),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                Gap(2.h),
                Text(
                  entry.time,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
                ),
              ],
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'حذف',
                icon: Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20.sp),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String ymd) {
    try {
      final d = DateTime.parse(ymd);
      return DateFormat('dd/MM/yyyy', 'ar').format(d);
    } catch (_) {
      return ymd;
    }
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined,
              size: 64.sp, color: AppColors.grey300),
          Gap(12.h),
          Text(
            'لا توجد سجلات حضور',
            style: TextStyle(fontSize: 14.sp, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56.sp, color: AppColors.error),
          Gap(12.h),
          Text('تعذّر تحميل السجل',
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey700)),
          Gap(12.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
