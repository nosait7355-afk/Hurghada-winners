import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final FlutterSecureStorage _storage;

  const TokenManager(this._storage);

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (kDebugMode) {
        debugPrint('[TOKEN] getToken() → ${token != null ? "FOUND(${token.length}chars)" : "NULL"}');
      }
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('[TOKEN] getToken() → EXCEPTION: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      if (kDebugMode) debugPrint('[TOKEN] saveToken() → writing to secure storage...');
      await _storage.write(key: AppConstants.tokenKey, value: token);
      if (kDebugMode) debugPrint('[TOKEN] saveToken() → DONE ✓');
    } catch (e) {
      if (kDebugMode) debugPrint('[TOKEN] saveToken() → EXCEPTION: $e');
      rethrow;
    }
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<void> clearToken() async {
    if (kDebugMode) debugPrint('[TOKEN] clearToken() → deleting tokens');
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.sessionTypeKey);
    if (kDebugMode) debugPrint('[TOKEN] clearToken() → DONE ✓');
  }

  // نوع الجلسة الحالية: 'admin' (مدير أكاديمية/super_admin) أو 'player' (لاعب).
  // يُستخدم عند إعادة تشغيل التطبيق لتحديد أي نقطة "me" نستدعي. الأكاديمية
  // واللاعب لا يتشاركان جلسة في آنٍ واحد على نفس الجهاز.
  Future<void> saveSessionType(String type) async {
    await _storage.write(key: AppConstants.sessionTypeKey, value: type);
  }

  Future<String?> getSessionType() async {
    try {
      return await _storage.read(key: AppConstants.sessionTypeKey);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasToken() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final result = token != null && token.isNotEmpty;
      if (kDebugMode) debugPrint('[TOKEN] hasToken() → $result');
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('[TOKEN] hasToken() → EXCEPTION: $e → returning false');
      return false;
    }
  }
}
