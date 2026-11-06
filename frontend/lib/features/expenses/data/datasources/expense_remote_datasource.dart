import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/expenses/data/models/expense_model.dart';

abstract class ExpenseRemoteDatasource {
  /// [academyId]: أكاديمية super_admin التي يتصرف كها. يتجاهلها الخادم
  /// لباقي الأدوار (مُقيَّدة بأكاديمية التوكن)، فنمرّرها دائماً.
  Future<({List<ExpenseModel> expenses, int total, int page, int totalPages})> getExpenses({
    String? category,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
    String? academyId,
  });

  Future<ExpenseModel> createExpense({
    required String name,
    String? description,
    required double amount,
    required String date,
    required String category,
    String? academyId,
  });

  Future<ExpenseModel> updateExpense({
    required String id,
    String? name,
    String? description,
    double? amount,
    String? date,
    String? category,
  });

  Future<void> deleteExpense(String id);

  Future<({double totalAmount, int totalCount, Map<String, dynamic> byCategory})> getReport({
    required String startDate,
    required String endDate,
    String? academyId,
  });
}

class ExpenseRemoteDatasourceImpl implements ExpenseRemoteDatasource {
  final ApiClient _apiClient;
  ExpenseRemoteDatasourceImpl(this._apiClient);

  @override
  Future<({List<ExpenseModel> expenses, int total, int page, int totalPages})> getExpenses({
    String? category,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
    String? academyId,
  }) async {
    final response = await _apiClient.get('/expenses', queryParameters: {
      'page': page,
      'limit': limit,
      if (category != null) 'category': category,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (academyId != null) 'academyId': academyId,
    });
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>).map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      expenses: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<ExpenseModel> createExpense({
    required String name,
    String? description,
    required double amount,
    required String date,
    required String category,
    String? academyId,
  }) async {
    final response = await _apiClient.post('/expenses', data: {
      'name': name,
      if (description != null) 'description': description,
      'amount': amount,
      'date': date,
      'category': category,
      if (academyId != null) 'academyId': academyId,
    });
    final body = response.data as Map<String, dynamic>;
    return ExpenseModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<ExpenseModel> updateExpense({
    required String id,
    String? name,
    String? description,
    double? amount,
    String? date,
    String? category,
  }) async {
    final response = await _apiClient.put('/expenses/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
    });
    final body = response.data as Map<String, dynamic>;
    return ExpenseModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _apiClient.delete('/expenses/$id');
  }

  @override
  Future<({double totalAmount, int totalCount, Map<String, dynamic> byCategory})> getReport({
    required String startDate,
    required String endDate,
    String? academyId,
  }) async {
    final response = await _apiClient.get('/expenses/report', queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
      if (academyId != null) 'academyId': academyId,
    });
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return (
      totalAmount: (data['totalAmount'] as num).toDouble(),
      totalCount: (data['totalCount'] as num).toInt(),
      byCategory: data['byCategory'] as Map<String, dynamic>,
    );
  }
}
