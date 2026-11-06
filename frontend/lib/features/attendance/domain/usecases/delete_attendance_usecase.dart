import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

/// حذف سجل حضور (للإدارة فقط — الخادم يفرض الدور).
class DeleteAttendanceUsecase extends UseCase<void, String> {
  final AttendanceRepository _repository;

  DeleteAttendanceUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteAttendance(id);
}
