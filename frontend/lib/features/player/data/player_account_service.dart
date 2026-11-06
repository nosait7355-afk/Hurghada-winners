import 'package:hurghada_winners/core/network/api_client.dart';

/// خدمة إدارة حساب دخول اللاعب من لوحة الأكاديمية (Player Portal).
/// إضافية بالكامل — لا تمسّ أي مسار أو Provider قائم، وتُستخدم من
/// كل المنصات (Android / Windows / Flutter Web) بنفس الكود.
class PlayerAccountService {
  final ApiClient _api;
  PlayerAccountService(this._api);

  /// حالة حساب اللاعب: { portalEnabled, hasAccount, account: {username,isActive}? }
  Future<Map<String, dynamic>> getAccount(String playerId) async {
    final res = await _api.get<Map<String, dynamic>>('/players/$playerId/account');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  /// إنشاء حساب — يعيد { username, password } (كلمة المرور تُعرض مرة واحدة).
  Future<Map<String, dynamic>> createAccount(String playerId) async {
    final res =
        await _api.post<Map<String, dynamic>>('/players/$playerId/create-account');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  /// تغيير كلمة المرور يدوياً.
  Future<void> changePassword(String playerId, String password) async {
    await _api.patch<Map<String, dynamic>>(
      '/players/$playerId/password',
      data: {'password': password, 'confirmPassword': password},
    );
  }

  /// إعادة إنشاء كلمة مرور عشوائية — يعيد { username, password }.
  Future<Map<String, dynamic>> resetPassword(String playerId) async {
    final res = await _api
        .patch<Map<String, dynamic>>('/players/$playerId/reset-password');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  /// تفعيل/تعطيل الحساب.
  Future<void> toggleAccount(String playerId, {required bool isActive}) async {
    await _api.patch<Map<String, dynamic>>(
      '/players/$playerId/toggle-account',
      data: {'isActive': isActive},
    );
  }

  /// إحصائية حسابات اللاعبين للوحة التحكم:
  /// { portalEnabled, withAccount, withoutAccount }
  Future<Map<String, dynamic>> accountStats({String? academyId}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/players/account-stats',
      queryParameters: {if (academyId != null) 'academyId': academyId},
    );
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }
}
