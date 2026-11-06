import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:dartz/dartz.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, AttendanceRecordResult>> recordAttendance({
    String? code,
    String? playerId,
    required String localDate,
    required String localTime,
    AttendanceKind? mode,
  });

  Future<Either<Failure, AttendanceLogResult>> getAttendanceLog({
    String? academyId,
    String? date,
    String? startDate,
    String? endDate,
    String? sport,
    String? playerId,
    int page,
    int limit,
  });

  Future<Either<Failure, AttendanceReport>> getAttendanceReport({
    String? academyId,
    String? sport,
    String subscription,
  });

  Future<Either<Failure, List<AttendancePlayer>>> searchPlayers({
    String? academyId,
    required String query,
    String? sport,
  });

  Future<Either<Failure, AttendancePlayerSummary>> getPlayerSummary(
      String playerId);

  Future<Either<Failure, void>> deleteAttendance(String id);
}
