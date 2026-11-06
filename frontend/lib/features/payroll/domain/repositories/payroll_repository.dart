import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/payroll/domain/entities/payroll_entity.dart';
import 'package:dartz/dartz.dart';

abstract class PayrollRepository {
  Future<Either<Failure, List<PayrollEntity>>> generatePayroll({required String month, String? staffId, bool force = false, String? academyId});
  Future<Either<Failure, List<PayrollEntity>>> getPayrollList({String? month, String? staffId, String? status, String? academyId});
  Future<Either<Failure, ({List<PayrollReportRow> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})>> getPayrollReport(String month, {String? academyId});
  Future<Either<Failure, PayrollEntity>> markPaid(String id);
}
