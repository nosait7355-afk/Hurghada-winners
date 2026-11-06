import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/academy/data/models/academy_model.dart';

abstract class AcademyRemoteDatasource {
  Future<List<AcademyModel>> getAcademies();
  Future<AcademyModel> getAcademyById(String id);
  Future<AcademyModel> createAcademy(Map<String, dynamic> data);
  Future<AcademyModel> updateAcademy(String id, Map<String, dynamic> data);
  Future<void> deleteAcademy(String id);
}

class AcademyRemoteDatasourceImpl implements AcademyRemoteDatasource {
  final ApiClient _apiClient;
  AcademyRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<AcademyModel>> getAcademies() async {
    final response = await _apiClient.get('/academies');
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((e) => AcademyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AcademyModel> getAcademyById(String id) async {
    final response = await _apiClient.get('/academies/$id');
    final data = response.data as Map<String, dynamic>;
    return AcademyModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<AcademyModel> createAcademy(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/academies', data: data);
    final responseData = response.data as Map<String, dynamic>;
    return AcademyModel.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  @override
  Future<AcademyModel> updateAcademy(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/academies/$id', data: data);
    final responseData = response.data as Map<String, dynamic>;
    return AcademyModel.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAcademy(String id) async {
    await _apiClient.delete('/academies/$id');
  }
}
