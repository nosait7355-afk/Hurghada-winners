import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/core/network/token_manager.dart';
import 'package:hurghada_winners/core/utils/multipart/image_multipart_helper.dart';
import 'package:dio/dio.dart';

/// خدمة تسجيل أكاديمية جديدة (Nosait SaaS). تنشئ Academy + Admin + Trial
/// وتحفظ التوكن مباشرة لتسجيل دخول تلقائي.
class AcademyRegistrationService {
  final ApiClient _api;
  final TokenManager _tokenManager;

  AcademyRegistrationService(this._api, this._tokenManager);

  /// يعيد بيانات المستخدم عند النجاح، أو يرمي استثناءً برسالة عربية عند الفشل.
  Future<Map<String, dynamic>> register({
    required String academyName,
    required String adminName,
    required String phone,
    required String email,
    required String city,
    required String sport,
    required String password,
    String? currency,
    String? logoPath,
  }) async {
    Response<dynamic> response;
    if (logoPath != null && logoPath.isNotEmpty) {
      final formData = FormData.fromMap({
        'academyName': academyName,
        'adminName': adminName,
        'phone': phone,
        'email': email,
        'city': city,
        'sport': sport,
        'password': password,
        if (currency != null) 'currency': currency,
        'logo': await buildImageMultipart(logoPath, filename: 'academy_logo.jpg'),
      });
      response = await _api.postMultipart<Map<String, dynamic>>(
        '/register-academy',
        data: formData,
      );
    } else {
      response = await _api.post<Map<String, dynamic>>(
        '/register-academy',
        data: {
          'academyName': academyName,
          'adminName': adminName,
          'phone': phone,
          'email': email,
          'city': city,
          'sport': sport,
          'password': password,
          if (currency != null) 'currency': currency,
        },
      );
    }

    final body = response.data as Map<String, dynamic>;
    final token = body['token'] as String?;
    final refresh = body['refreshToken'] as String?;
    if (token != null) {
      await _tokenManager.saveToken(token);
      await _tokenManager.saveSessionType('admin');
      if (refresh != null) await _tokenManager.saveRefreshToken(refresh);
    }
    return body['data'] as Map<String, dynamic>;
  }
}
