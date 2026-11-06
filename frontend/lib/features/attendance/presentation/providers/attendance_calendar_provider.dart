import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// يوم في سجل اللاعب: حضر أو غاب (الغياب فقط في أيام تدريبه).
class AttendanceCalendarDay {
  final String date; // YYYY-MM-DD
  final String weekday;
  final bool present;
  final bool scheduled;
  final String time;
  final String kind;
  final String? id;

  const AttendanceCalendarDay({
    required this.date,
    required this.weekday,
    required this.present,
    required this.scheduled,
    this.time = '',
    this.kind = 'regular',
    this.id,
  });

  factory AttendanceCalendarDay.fromJson(Map<String, dynamic> j) =>
      AttendanceCalendarDay(
        date: j['date'] as String? ?? '',
        weekday: j['weekday'] as String? ?? '',
        present: j['status'] == 'present',
        scheduled: j['scheduled'] as bool? ?? false,
        time: j['time'] as String? ?? '',
        kind: j['kind'] as String? ?? 'regular',
        id: j['id'] as String?,
      );
}

class AttendanceCalendar {
  final int present;
  final int absent;
  final List<AttendanceCalendarDay> days;
  const AttendanceCalendar(
      {required this.present, required this.absent, required this.days});
}

class AttendanceCalendarKey {
  final String playerId;
  final int rangeDays;
  const AttendanceCalendarKey(this.playerId, this.rangeDays);

  @override
  bool operator ==(Object other) =>
      other is AttendanceCalendarKey &&
      other.playerId == playerId &&
      other.rangeDays == rangeDays;

  @override
  int get hashCode => Object.hash(playerId, rangeDays);
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final attendanceCalendarProvider = FutureProvider.autoDispose
    .family<AttendanceCalendar, AttendanceCalendarKey>((ref, key) async {
  final now = DateTime.now();
  final from = now.subtract(Duration(days: key.rangeDays - 1));
  final response = await sl<ApiClient>().get(
    '/attendance/player/${key.playerId}/calendar',
    queryParameters: {
      'from': _ymd(from),
      'to': _ymd(now),
      'localDate': _ymd(now),
    },
  );
  final data =
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  return AttendanceCalendar(
    present: (data['present'] as num?)?.toInt() ?? 0,
    absent: (data['absent'] as num?)?.toInt() ?? 0,
    days: ((data['days'] as List<dynamic>?) ?? const [])
        .map((e) => AttendanceCalendarDay.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});

/// سجل يومي لفترة محددة (مثل فترة اشتراك) — from/to بصيغة YYYY-MM-DD.
/// الخادم يقصّ "to" عند اليوم، فاشتراك نشط يُعرض حتى اليوم فقط.
final attendanceRangeProvider = FutureProvider.autoDispose.family<
    AttendanceCalendar,
    ({String playerId, String from, String to})>((ref, key) async {
  final response = await sl<ApiClient>().get(
    '/attendance/player/${key.playerId}/calendar',
    queryParameters: {
      'from': key.from,
      'to': key.to,
      'localDate': _ymd(DateTime.now()),
    },
  );
  final data =
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  return AttendanceCalendar(
    present: (data['present'] as num?)?.toInt() ?? 0,
    absent: (data['absent'] as num?)?.toInt() ?? 0,
    days: ((data['days'] as List<dynamic>?) ?? const [])
        .map((e) => AttendanceCalendarDay.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});
