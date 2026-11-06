import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/expenses/domain/entities/expense_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, ({List<ExpenseEntity> expenses, int total, int page, int totalPages})>> getExpenses({
    String? category,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
    String? academyId,
  });

  Future<Either<Failure, ExpenseEntity>> createExpense({
    required String name,
    String? description,
    required double amount,
    required String date,
    required String category,
    String? academyId,
  });

  Future<Either<Failure, ExpenseEntity>> updateExpense({
    required String id,
    String? name,
    String? description,
    double? amount,
    String? date,
    String? category,
  });

  Future<Either<Failure, void>> deleteExpense(String id);

  Future<Either<Failure, ExpenseReportData>> getReport({
    required String startDate,
    required String endDate,
    String? academyId,
  });
}
