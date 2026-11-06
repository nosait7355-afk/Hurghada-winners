import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class RecordAttendanceParams {
  final String? code;
  final String? playerId;
  final String localDate;
  final String localTime;

  /// نوع الحضور للاعب منتهي الاشتراك (payLater/makeup/free) — null للعادي.
  final AttendanceKind? mode;

  const RecordAttendanceParams({
    this.code,
    this.playerId,
    required this.localDate,
    required this.localTime,
    this.mode,
  });
}

class RecordAttendanceUsecase
    extends UseCase<AttendanceRecordResult, RecordAttendanceParams> {
  final AttendanceRepository _repository;

  RecordAttendanceUsecase(this._repository);

  @override
  Future<Either<Failure, AttendanceRecordResult>> call(
      RecordAttendanceParams params) {
    return _repository.recordAttendance(
      code: params.code,
      playerId: params.playerId,
      localDate: params.localDate,
      localTime: params.localTime,
      mode: params.mode,
    );
  }
}
