import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/user/data/models/user_management_model.dart';

abstract class UserRemoteDatasource {
  Future<List<UserManagementModel>> getUsersByAcademy(String academyId);
  Future<UserManagementModel> getUserById(String id);
  Future<UserManagementModel> createUser(Map<String, dynamic> data);
  Future<UserManagementModel> updateUser(String id, Map<String, dynamic> data);
  Future<void> deleteUser(String id);
  Future<void> activateUser(String id);
  Future<void> deactivateUser(String id);
  Future<void> resetPassword(String id, String newPassword);
}

class UserRemoteDatasourceImpl implements UserRemoteDatasource {
  final ApiClient _apiClient;

  UserRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<UserManagementModel>> getUsersByAcademy(String academyId) async {
    final response = await _apiClient.get('/users/academy/$academyId');
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) =>
            UserManagementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserManagementModel> getUserById(String id) async {
    final response = await _apiClient.get('/users/$id');
    final data = response.data as Map<String, dynamic>;
    return UserManagementModel.fromJson(
        data['data'] as Map<String, dynamic>);
  }

  @override
  Future<UserManagementModel> createUser(Map<String, dynamic> data) async {
    assert(() {
      // ignore: avoid_print
      print('[UserRemoteDatasource.createUser] data=$data');
      return true;
    }());
    final response = await _apiClient.post('/users', data: data);
    final responseData = response.data as Map<String, dynamic>;
    return UserManagementModel.fromJson(
        responseData['data'] as Map<String, dynamic>);
  }

  @override
  Future<UserManagementModel> updateUser(
      String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/users/$id', data: data);
    final responseData = response.data as Map<String, dynamic>;
    return UserManagementModel.fromJson(
        responseData['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(String id) async {
    await _apiClient.delete('/users/$id');
  }

  @override
  Future<void> activateUser(String id) async {
    await _apiClient.patch('/users/$id/activate');
  }

  @override
  Future<void> deactivateUser(String id) async {
    await _apiClient.patch('/users/$id/deactivate');
  }

  @override
  Future<void> resetPassword(String id, String newPassword) async {
    await _apiClient.patch('/users/$id/reset-password',
        data: {'newPassword': newPassword});
  }
}
