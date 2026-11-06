import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:hurghada_winners/features/expenses/domain/entities/expense_entity.dart';
import 'package:hurghada_winners/features/expenses/domain/repositories/expense_repository.dart';
import 'package:dartz/dartz.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDatasource _remoteDatasource;
  ExpenseRepositoryImpl({required ExpenseRemoteDatasource remoteDatasource}) : _remoteDatasource = remoteDatasource;

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
  Future<Either<Failure, ({List<ExpenseEntity> expenses, int total, int page, int totalPages})>> getExpenses({
    String? category,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
    String? academyId,
  }) {
    return _wrap(() async {
      final result = await _remoteDatasource.getExpenses(category: category, startDate: startDate, endDate: endDate, page: page, limit: limit, academyId: academyId);
      return (
        expenses: result.expenses.map((m) => m.toEntity()).toList(),
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      );
    });
  }

  @override
  Future<Either<Failure, ExpenseEntity>> createExpense({
    required String name,
    String? description,
    required double amount,
    required String date,
    required String category,
    String? academyId,
  }) {
    return _wrap(() async => (await _remoteDatasource.createExpense(name: name, description: description, amount: amount, date: date, category: category, academyId: academyId)).toEntity());
  }

  @override
  Future<Either<Failure, ExpenseEntity>> updateExpense({
    required String id,
    String? name,
    String? description,
    double? amount,
    String? date,
    String? category,
  }) {
    return _wrap(() async => (await _remoteDatasource.updateExpense(id: id, name: name, description: description, amount: amount, date: date, category: category)).toEntity());
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) {
    return _wrap(() => _remoteDatasource.deleteExpense(id));
  }

  @override
  Future<Either<Failure, ExpenseReportData>> getReport({
    required String startDate,
    required String endDate,
    String? academyId,
  }) {
    return _wrap(() async {
      final result = await _remoteDatasource.getReport(startDate: startDate, endDate: endDate, academyId: academyId);
      final byCategory = <String, ({double total, int count})>{};
      result.byCategory.forEach((key, value) {
        final v = value as Map<String, dynamic>;
        byCategory[key] = (total: (v['total'] as num).toDouble(), count: (v['count'] as num).toInt());
      });
      return ExpenseReportData(totalAmount: result.totalAmount, totalCount: result.totalCount, byCategory: byCategory);
    });
  }
}
