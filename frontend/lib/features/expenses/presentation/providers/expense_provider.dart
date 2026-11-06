import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/expenses/domain/entities/expense_entity.dart';
import 'package:hurghada_winners/features/expenses/domain/repositories/expense_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensesState {
  final List<ExpenseEntity> expenses;
  final int total;
  final String? categoryFilter;
  final String? startDate;
  final String? endDate;

  /// أكاديمية super_admin التي يتصرف كها — نحتفظ بها ليعمل refresh بعد
  /// الإضافة/التعديل/الحذف. null لباقي الأدوار (الخادم يستنتجها من التوكن).
  final String? academyId;

  const ExpensesState({
    this.expenses = const [],
    this.total = 0,
    this.categoryFilter,
    this.startDate,
    this.endDate,
    this.academyId,
  });
}

class ExpensesNotifier extends AsyncNotifier<ExpensesState> {
  ExpenseRepository get _repo => sl<ExpenseRepository>();

  @override
  Future<ExpensesState> build() async => const ExpensesState();

  Future<void> load({String? category, String? startDate, String? endDate, String? academyId}) async {
    // نتمسّك بالأكاديمية الأخيرة إن لم تُمرَّر (مثلاً في refresh بعد تعديل).
    final scope = academyId ?? state.valueOrNull?.academyId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getExpenses(category: category, startDate: startDate, endDate: endDate, limit: 200, academyId: scope);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (data) => ExpensesState(expenses: data.expenses, total: data.total, categoryFilter: category, startDate: startDate, endDate: endDate, academyId: scope),
      );
    });
  }

  Future<void> refresh() async {
    final s = state.valueOrNull;
    await load(category: s?.categoryFilter, startDate: s?.startDate, endDate: s?.endDate, academyId: s?.academyId);
  }

  Future<String?> createExpense({required String name, String? description, required double amount, required String date, required String category, String? academyId}) async {
    final result = await _repo.createExpense(name: name, description: description, amount: amount, date: date, category: category, academyId: academyId ?? state.valueOrNull?.academyId);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> updateExpense({required String id, String? name, String? description, double? amount, String? date, String? category}) async {
    final result = await _repo.updateExpense(id: id, name: name, description: description, amount: amount, date: date, category: category);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> deleteExpense(String id) async {
    final result = await _repo.deleteExpense(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }
}

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, ExpensesState>(ExpensesNotifier.new);

class ExpenseReportNotifier extends AsyncNotifier<ExpenseReportData?> {
  ExpenseRepository get _repo => sl<ExpenseRepository>();

  @override
  Future<ExpenseReportData?> build() async => null;

  Future<void> load({required String startDate, required String endDate, String? academyId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getReport(startDate: startDate, endDate: endDate, academyId: academyId);
      return result.fold((failure) => throw Exception(failure.message), (data) => data);
    });
  }
}

final expenseReportProvider = AsyncNotifierProvider<ExpenseReportNotifier, ExpenseReportData?>(ExpenseReportNotifier.new);
