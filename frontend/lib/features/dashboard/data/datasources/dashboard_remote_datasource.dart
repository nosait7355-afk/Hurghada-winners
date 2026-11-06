import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/dashboard/data/models/dashboard_models.dart';

abstract class DashboardRemoteDatasource {
  Future<DashboardStatsModel> getStats({String? academyId});
  Future<List<RevenueByMonthModel>> getRevenueByMonth({String? academyId});
  Future<SubscriptionsByTypeModel> getSubscriptionsByType({String? academyId});
  Future<List<PlayersByBirthYearModel>> getPlayersByBirthYear({String? academyId});
  Future<EvaluationDistributionModel> getEvaluationDistribution({String? academyId});
  Future<RecentActivitiesModel> getRecentActivities({String? academyId});
}

class DashboardRemoteDatasourceImpl implements DashboardRemoteDatasource {
  final ApiClient _apiClient;

  DashboardRemoteDatasourceImpl(this._apiClient);

  Map<String, dynamic>? _buildQuery(String? academyId) {
    if (academyId == null) return null;
    return {'academyId': academyId};
  }

  @override
  Future<DashboardStatsModel> getStats({String? academyId}) async {
    final response = await _apiClient.get(
      '/dashboard/stats',
      queryParameters: _buildQuery(academyId),
    );
    final body = response.data as Map<String, dynamic>;
    return DashboardStatsModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<RevenueByMonthModel>> getRevenueByMonth({String? academyId}) async {
    final response = await _apiClient.get(
      '/dashboard/revenue-by-month',
      queryParameters: _buildQuery(academyId),
    );
    final body = response.data as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((e) => RevenueByMonthModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SubscriptionsByTypeModel> getSubscriptionsByType({String? academyId}) async {
    final response = await _apiClient.get(
      '/dashboard/subscriptions-by-type',
      queryParameters: _buildQuery(academyId),
    );
    final body = response.data as Map<String, dynamic>;
    return SubscriptionsByTypeModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<PlayersByBirthYearModel>> getPlayersByBirthYear({String? academyId}) async {
    final response = await _apiClient.get(
      '/dashboard/players-by-birth-year',
      queryParameters: _buildQuery(academyId),
    );
    final body = response.data as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((e) => PlayersByBirthYearModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EvaluationDistributionModel> getEvaluationDistribution({String? academyId}) async {
    final response = await _apiClient.get(
      '/dashboard/evaluation-distribution',
      queryParameters: _buildQuery(academyId),
    );
    final body = response.data as Map<String, dynamic>;
    return EvaluationDistributionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<RecentActivitiesModel> getRecentActivities({String? academyId}) async {
    final response = await _apiClient.get(
      '/dashboard/recent-activities',
      queryParameters: _buildQuery(academyId),
    );
    final body = response.data as Map<String, dynamic>;
    return RecentActivitiesModel.fromList((body['data'] as List<dynamic>?) ?? []);
  }
}
