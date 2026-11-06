import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class GetAttendanceReportParams {
  final String? academyId;
  final String? sport;

  /// 'active' (نشطون فقط) أو 'all'.
  final String subscription;

  const GetAttendanceReportParams({
    this.academyId,
    this.sport,
    this.subscription = 'active',
  });
}

class GetAttendanceReportUsecase
    extends UseCase<AttendanceReport, GetAttendanceReportParams> {
  final AttendanceRepository _repository;

  GetAttendanceReportUsecase(this._repository);

  @override
  Future<Either<Failure, AttendanceReport>> call(
      GetAttendanceReportParams params) {
    return _repository.getAttendanceReport(
      academyId: params.academyId,
      sport: params.sport,
      subscription: params.subscription,
    );
  }
}
