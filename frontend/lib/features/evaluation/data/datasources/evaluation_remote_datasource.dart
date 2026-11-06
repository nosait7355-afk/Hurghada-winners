import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/evaluation/data/models/evaluation_model.dart';

abstract class EvaluationRemoteDatasource {
  Future<
      ({
        List<EvaluationModel> evaluations,
        int total,
        int page,
        int totalPages,
      })> getEvaluationsByPlayer({
    required String playerId,
    int page = 1,
    int limit = 10,
  });

  Future<EvaluationModel?> getLatestEvaluation(String playerId);

  Future<EvaluationModel> getEvaluationById(String id);

  Future<EvaluationModel> createEvaluation({
    required String playerId,
    required double fitness,
    required double basicSkills,
    required double attack,
    required double defense,
    required double commitment,
    String? notes,
    String? academyId,
    DateTime? evaluationDate,
  });

  Future<EvaluationModel> updateEvaluation({
    required String id,
    double? fitness,
    double? basicSkills,
    double? attack,
    double? defense,
    double? commitment,
    String? notes,
    DateTime? evaluationDate,
  });

  Future<void> deleteEvaluation(String id);

  Future<
      ({
        List<EvaluationModel> evaluations,
        int total,
        int page,
        int totalPages,
      })> getEvaluationsByAcademy({
    required String academyId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 100,
  });
}

class EvaluationRemoteDatasourceImpl implements EvaluationRemoteDatasource {
  final ApiClient _apiClient;

  EvaluationRemoteDatasourceImpl(this._apiClient);

  @override
  Future<
      ({
        List<EvaluationModel> evaluations,
        int total,
        int page,
        int totalPages,
      })> getEvaluationsByPlayer({
    required String playerId,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    final response = await _apiClient.get(
      '/players/$playerId/evaluations',
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => EvaluationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      evaluations: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<EvaluationModel?> getLatestEvaluation(String playerId) async {
    final response =
        await _apiClient.get('/evaluations/player/$playerId/latest');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data == null) return null;
    return EvaluationModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<EvaluationModel> getEvaluationById(String id) async {
    final response = await _apiClient.get('/evaluations/$id');
    final body = response.data as Map<String, dynamic>;
    return EvaluationModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<EvaluationModel> createEvaluation({
    required String playerId,
    required double fitness,
    required double basicSkills,
    required double attack,
    required double defense,
    required double commitment,
    String? notes,
    String? academyId,
    DateTime? evaluationDate,
  }) async {
    final data = <String, dynamic>{
      'playerId': playerId,
      'fitness': fitness,
      'basicSkills': basicSkills,
      'attack': attack,
      'defense': defense,
      'commitment': commitment,
      if (notes != null) 'notes': notes,
      if (academyId != null) 'academyId': academyId,
      if (evaluationDate != null)
        'evaluationDate': evaluationDate.toIso8601String(),
    };
    final response = await _apiClient.post('/evaluations', data: data);
    final body = response.data as Map<String, dynamic>;
    return EvaluationModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<EvaluationModel> updateEvaluation({
    required String id,
    double? fitness,
    double? basicSkills,
    double? attack,
    double? defense,
    double? commitment,
    String? notes,
    DateTime? evaluationDate,
  }) async {
    final data = <String, dynamic>{
      if (fitness != null) 'fitness': fitness,
      if (basicSkills != null) 'basicSkills': basicSkills,
      if (attack != null) 'attack': attack,
      if (defense != null) 'defense': defense,
      if (commitment != null) 'commitment': commitment,
      if (notes != null) 'notes': notes,
      if (evaluationDate != null)
        'evaluationDate': evaluationDate.toIso8601String(),
    };
    final response = await _apiClient.put('/evaluations/$id', data: data);
    final body = response.data as Map<String, dynamic>;
    return EvaluationModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteEvaluation(String id) async {
    await _apiClient.delete('/evaluations/$id');
  }

  @override
  Future<
      ({
        List<EvaluationModel> evaluations,
        int total,
        int page,
        int totalPages,
      })> getEvaluationsByAcademy({
    required String academyId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };
    final response = await _apiClient.get(
      '/evaluations/academy/$academyId',
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => EvaluationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      evaluations: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }
}
