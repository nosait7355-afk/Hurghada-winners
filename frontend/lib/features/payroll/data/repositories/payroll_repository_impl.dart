import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/payroll/data/datasources/payroll_remote_datasource.dart';
import 'package:hurghada_winners/features/payroll/domain/entities/payroll_entity.dart';
import 'package:hurghada_winners/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:dartz/dartz.dart';

class PayrollRepositoryImpl implements PayrollRepository {
  final PayrollRemoteDatasource _remoteDatasource;
  PayrollRepositoryImpl({required PayrollRemoteDatasource remoteDatasource}) : _remoteDatasource = remoteDatasource;

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on NotFoundException {
      return const Left(NotFoundFailure());
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
  Future<Either<Failure, List<PayrollEntity>>> generatePayroll({required String month, String? staffId, bool force = false, String? academyId}) {
    return _wrap(() async => (await _remoteDatasource.generatePayroll(month: month, staffId: staffId, force: force, academyId: academyId))
        .map((m) => m.toEntity())
        .toList());
  }

  @override
  Future<Either<Failure, List<PayrollEntity>>> getPayrollList({String? month, String? staffId, String? status, String? academyId}) {
    return _wrap(() async => (await _remoteDatasource.getPayrollList(month: month, staffId: staffId, status: status, academyId: academyId))
        .map((m) => m.toEntity())
        .toList());
  }

  @override
  Future<Either<Failure, ({List<PayrollReportRow> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})>> getPayrollReport(String month, {String? academyId}) {
    return _wrap(() async {
      final result = await _remoteDatasource.getPayrollReport(month, academyId: academyId);
      return (
        report: result.report.map((m) => m.toEntity()).toList(),
        totalBaseSalary: result.totalBaseSalary,
        totalDeductions: result.totalDeductions,
        totalNetSalary: result.totalNetSalary,
      );
    });
  }

  @override
  Future<Either<Failure, PayrollEntity>> markPaid(String id) {
    return _wrap(() async => (await _remoteDatasource.markPaid(id)).toEntity());
  }
}
