import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// نوع شاشة الدخول التي حُفظ منها الحساب.
enum SavedAccountKind { admin, player }

/// حساب محفوظ على الجهاز للدخول بضغطة من شاشة تسجيل الدخول.
class SavedAccount {
  final String username;
  final String password;
  final String displayName;
  final String? imageUrl;

  const SavedAccount({
    required this.username,
    required this.password,
    required this.displayName,
    this.imageUrl,
  });

  factory SavedAccount.fromJson(Map<String, dynamic> j) => SavedAccount(
        username: j['username'] as String? ?? '',
        password: j['password'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        imageUrl: j['imageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'displayName': displayName,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

/// يحفظ الحسابات في FlutterSecureStorage (مشفّرة) — لا SharedPreferences،
/// لأن القائمة تحمل كلمات المرور.
class SavedAccountsStore {
  final FlutterSecureStorage _storage;
  const SavedAccountsStore(this._storage);

  static String _key(SavedAccountKind kind) => 'saved_accounts_v1_${kind.name}';

  /// الاسم الأول فقط — هو ما يظهر على كارت الحساب.
  static String firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  Future<List<SavedAccount>> load(SavedAccountKind kind) async {
    try {
      final raw = await _storage.read(key: _key(kind));
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => SavedAccount.fromJson(e as Map<String, dynamic>))
          .where((a) => a.username.isNotEmpty)
          .toList();
    } catch (_) {
      // تخزين تالف/غير مقروء — نتصرف كأنه فارغ بدل كسر شاشة الدخول.
      return [];
    }
  }

  Future<void> _write(SavedAccountKind kind, List<SavedAccount> list) {
    return _storage.write(
      key: _key(kind),
      value: jsonEncode(list.map((a) => a.toJson()).toList()),
    );
  }

  /// يضيف الحساب أو يحدّث بياناته (باسم المستخدم نفسه) ويضعه أولاً.
  Future<void> upsert(SavedAccountKind kind, SavedAccount account) async {
    final list = await load(kind);
    list.removeWhere(
        (a) => a.username.toLowerCase() == account.username.toLowerCase());
    list.insert(0, account);
    await _write(kind, list);
  }

  Future<bool> contains(SavedAccountKind kind, String username) async {
    final list = await load(kind);
    return list.any((a) => a.username.toLowerCase() == username.toLowerCase());
  }

  Future<void> remove(SavedAccountKind kind, String username) async {
    final list = await load(kind);
    list.removeWhere((a) => a.username.toLowerCase() == username.toLowerCase());
    await _write(kind, list);
  }
}
