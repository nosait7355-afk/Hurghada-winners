import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDatasource {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateProfile({required String name});
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient _apiClient;
  AuthRemoteDatasourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> logout() async {
    await _apiClient.post('/auth/logout');
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> updateProfile({required String name}) async {
    final response = await _apiClient.patch('/auth/me', data: {'name': name});
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
