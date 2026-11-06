import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hurghada_winners/features/attendance/domain/usecases/get_attendance_log_usecase.dart';
import 'package:hurghada_winners/features/attendance/domain/usecases/get_attendance_report_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حجم صفحة سجل الحضور — "إظهار المزيد" يضيف صفحة بهذا الحجم.
const int kAttendanceLogPageSize = 100;

// ---------------------------------------------------------------------------
// Filter keys (Equatable so the .family providers cache correctly)
// ---------------------------------------------------------------------------

class AttendanceLogFilter extends Equatable {
  final String academyId;
  final String? date; // 'YYYY-MM-DD'
  final String? sport; // null/'' = الكل
  final String? playerId;
  final int page;

  const AttendanceLogFilter({
    required this.academyId,
    this.date,
    this.sport,
    this.playerId,
    this.page = 1,
  });

  AttendanceLogFilter copyWithPage(int page) => AttendanceLogFilter(
        academyId: academyId,
        date: date,
        sport: sport,
        playerId: playerId,
        page: page,
      );

  @override
  List<Object?> get props => [academyId, date, sport, playerId, page];
}

class AttendanceReportFilter extends Equatable {
  final String academyId;
  final String? sport;

  /// 'active' (نشطون فقط) أو 'all'.
  final String subscription;

  const AttendanceReportFilter({
    required this.academyId,
    this.sport,
    this.subscription = 'active',
  });

  @override
  List<Object?> get props => [academyId, sport, subscription];
}

class AttendancePlayerSearchKey extends Equatable {
  final String academyId;
  final String query;
  final String? sport;

  const AttendancePlayerSearchKey({
    required this.academyId,
    required this.query,
    this.sport,
  });

  @override
  List<Object?> get props => [academyId, query, sport];
}

// ---------------------------------------------------------------------------
// Providers — كل واحد = طلب واحد لكل تركيبة فلاتر (يُخزّن مؤقتاً عبر family)
// ---------------------------------------------------------------------------

final attendanceLogProvider = FutureProvider.autoDispose
    .family<AttendanceLogResult, AttendanceLogFilter>((ref, filter) async {
  final result = await sl<GetAttendanceLogUsecase>()(GetAttendanceLogParams(
    academyId: filter.academyId,
    date: filter.date,
    sport: filter.sport,
    playerId: filter.playerId,
    page: filter.page,
    limit: kAttendanceLogPageSize,
  ));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});

final attendanceReportProvider = FutureProvider.autoDispose
    .family<AttendanceReport, AttendanceReportFilter>((ref, filter) async {
  final result = await sl<GetAttendanceReportUsecase>()(GetAttendanceReportParams(
    academyId: filter.academyId,
    sport: filter.sport,
    subscription: filter.subscription,
  ));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});

/// بحث لاعب في سجل الحضور (اسم أو كود) — على الخادم.
final attendancePlayerSearchProvider = FutureProvider.autoDispose
    .family<List<AttendancePlayer>, AttendancePlayerSearchKey>((ref, key) async {
  final result = await sl<AttendanceRepository>().searchPlayers(
    academyId: key.academyId,
    query: key.query,
    sport: key.sport,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (players) => players,
  );
});

/// ملخص حضور لاعب في اشتراكه الأخير.
final attendancePlayerSummaryProvider = FutureProvider.autoDispose
    .family<AttendancePlayerSummary, String>((ref, playerId) async {
  final result = await sl<AttendanceRepository>().getPlayerSummary(playerId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (summary) => summary,
  );
});
