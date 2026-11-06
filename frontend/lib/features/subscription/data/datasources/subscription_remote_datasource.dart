import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/subscription/data/models/subscription_model.dart';

abstract class SubscriptionRemoteDatasource {
  Future<List<SubscriptionModel>> getSubscriptionsByPlayer({
    required String playerId,
    String? status,
  });

  Future<
      ({
        List<SubscriptionModel> subscriptions,
        int total,
        int page,
        int totalPages,
      })> getSubscriptionsByAcademy({
    required String academyId,
    String? type,
    String? status,
    String? playerId,
    int page = 1,
    int limit = 20,
  });

  Future<SubscriptionModel> getSubscriptionById(String id);

  Future<SubscriptionModel> createSubscription({
    required String playerId,
    required String type,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? academyId,
  });

  Future<SubscriptionModel> updateNotes({
    required String id,
    required String notes,
  });

  Future<void> deleteSubscription(String id);

  Future<Map<String, dynamic>> getRevenueSummary(String academyId);
}

class SubscriptionRemoteDatasourceImpl implements SubscriptionRemoteDatasource {
  final ApiClient _apiClient;

  SubscriptionRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<SubscriptionModel>> getSubscriptionsByPlayer({
    required String playerId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
    };
    final response = await _apiClient.get(
      '/subscriptions/player/$playerId',
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<
      ({
        List<SubscriptionModel> subscriptions,
        int total,
        int page,
        int totalPages,
      })> getSubscriptionsByAcademy({
    required String academyId,
    String? type,
    String? status,
    String? playerId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (playerId != null) 'playerId': playerId,
    };
    final response = await _apiClient.get(
      '/subscriptions/academy/$academyId',
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      subscriptions: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<SubscriptionModel> getSubscriptionById(String id) async {
    final response = await _apiClient.get('/subscriptions/$id');
    final body = response.data as Map<String, dynamic>;
    return SubscriptionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionModel> createSubscription({
    required String playerId,
    required String type,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? academyId,
  }) async {
    final data = <String, dynamic>{
      'playerId': playerId,
      'type': type,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (academyId != null) 'academyId': academyId,
    };
    final response = await _apiClient.post('/subscriptions', data: data);
    final body = response.data as Map<String, dynamic>;
    return SubscriptionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionModel> updateNotes({
    required String id,
    required String notes,
  }) async {
    final response = await _apiClient.patch(
      '/subscriptions/$id/notes',
      data: {'notes': notes},
    );
    final body = response.data as Map<String, dynamic>;
    return SubscriptionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await _apiClient.delete('/subscriptions/$id');
  }

  @override
  Future<Map<String, dynamic>> getRevenueSummary(String academyId) async {
    final response =
        await _apiClient.get('/subscriptions/academy/$academyId/revenue');
    final body = response.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }
}
