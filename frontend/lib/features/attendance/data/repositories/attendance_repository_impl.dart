import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_report_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDatasource _remoteDatasource;

  AttendanceRepositoryImpl({required AttendanceRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  /// تحويل استثناءات الشبكة/الخادم إلى Failures — موحّد لكل النداءات.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on NotFoundException {
      return const Left(NotFoundFailure(message: 'اللاعب غير موجود — تأكد من الكود'));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, AttendanceRecordResult>> recordAttendance({
    String? code,
    String? playerId,
    required String localDate,
    required String localTime,
    AttendanceKind? mode,
  }) =>
      _guard(() => _remoteDatasource.recordAttendance(
            code: code,
            playerId: playerId,
            localDate: localDate,
            localTime: localTime,
            mode: mode,
          ));

  @override
  Future<Either<Failure, AttendanceLogResult>> getAttendanceLog({
    String? academyId,
    String? date,
    String? startDate,
    String? endDate,
    String? sport,
    String? playerId,
    int page = 1,
    int limit = 30,
  }) =>
      _guard(() => _remoteDatasource.getAttendanceLog(
            academyId: academyId,
            date: date,
            startDate: startDate,
            endDate: endDate,
            sport: sport,
            playerId: playerId,
            page: page,
            limit: limit,
          ));

  @override
  Future<Either<Failure, AttendanceReport>> getAttendanceReport({
    String? academyId,
    String? sport,
    String subscription = 'active',
  }) =>
      _guard(() => _remoteDatasource.getAttendanceReport(
            academyId: academyId,
            sport: sport,
            subscription: subscription,
          ));

  @override
  Future<Either<Failure, List<AttendancePlayer>>> searchPlayers({
    String? academyId,
    required String query,
    String? sport,
  }) =>
      _guard(() => _remoteDatasource.searchPlayers(
            academyId: academyId,
            query: query,
            sport: sport,
          ));

  @override
  Future<Either<Failure, AttendancePlayerSummary>> getPlayerSummary(
          String playerId) =>
      _guard(() => _remoteDatasource.getPlayerSummary(playerId));

  @override
  Future<Either<Failure, void>> deleteAttendance(String id) =>
      _guard(() => _remoteDatasource.deleteAttendance(id));
}
