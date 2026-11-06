import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/core/network/token_manager.dart';
import 'package:hurghada_winners/core/utils/multipart/image_multipart_helper.dart';
import 'package:dio/dio.dart';

/// خدمة بوابة اللاعب (Nosait SaaS): دخول اللاعب + لوحته + محادثته + إشعاراته.
/// تستخدم نفس ApiClient/التوكن؛ يُميَّز نوع الجلسة عبر sessionType='player'.
class PlayerApiService {
  final ApiClient _api;
  final TokenManager _tokenManager;

  PlayerApiService(this._api, this._tokenManager);

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/player/login',
      data: {'username': username, 'password': password},
    );
    final body = res.data as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token != null) {
      await _tokenManager.saveToken(token);
      await _tokenManager.saveSessionType('player');
    }
    return body['data'] as Map<String, dynamic>;
  }

  /// إرسال طلب انضمام لاعب جديد (تسجيل ذاتي — عام بلا تسجيل دخول سابق).
  /// عند النجاح يحفظ توكن اللاعب مباشرة (نفس آلية login) حتى يدخل التطبيق
  /// فوراً على شاشة "طلبك قيد المراجعة" دون خطوة تسجيل دخول إضافية.
  Future<Map<String, dynamic>> submitJoinRequest({
    required String academyId,
    required String fullName,
    required String birthDate, // yyyy-MM-dd
    required String parentName,
    required String parentRelationship,
    String? parentJob,
    required String parentPhone,
    String? playerPhone,
    String? notes,
    required String branch,
    required String loginPhone,
    required String password,
    List<String>? attendanceDays,
    String? imagePath,
    required String receiptPath,
  }) async {
    final formData = FormData.fromMap({
      'academyId': academyId,
      'fullName': fullName,
      'birthDate': birthDate,
      'parentName': parentName,
      'parentRelationship': parentRelationship,
      if (parentJob != null && parentJob.isNotEmpty) 'parentJob': parentJob,
      'parentPhone': parentPhone,
      if (playerPhone != null && playerPhone.isNotEmpty) 'playerPhone': playerPhone,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (attendanceDays != null && attendanceDays.isNotEmpty)
        'attendanceDays': attendanceDays.join(','),
      'branch': branch,
      'loginPhone': loginPhone,
      'password': password,
      'receipt': await buildImageMultipart(receiptPath, filename: 'receipt.jpg'),
      if (imagePath != null && imagePath.isNotEmpty)
        'image': await buildImageMultipart(imagePath, filename: 'player_image.jpg'),
    });

    final res = await _api.postMultipart<Map<String, dynamic>>(
      '/players/join-request',
      data: formData,
    );
    final body = res.data as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token != null) {
      await _tokenManager.saveToken(token);
      await _tokenManager.saveSessionType('player');
    }
    return body['data'] as Map<String, dynamic>;
  }

  // ── عائلة الحسابات ──
  /// باقي حسابات عائلة الحساب الحالي (فارغة إن لم يكن في عائلة).
  Future<List<Map<String, dynamic>>> family() async {
    final res = await _api.get<Map<String, dynamic>>('/auth/player/family');
    final data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? const [];
    return data.cast<Map<String, dynamic>>();
  }

  /// يبدّل لحساب آخر في نفس العائلة: يحفظ توكن الحساب الجديد تماماً كالدخول.
  Future<Map<String, dynamic>> switchAccount(String accountId) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/player/switch',
      data: {'accountId': accountId},
    );
    final body = res.data as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token == null) throw Exception('لم يتم استلام رمز الحساب');
    await _tokenManager.saveToken(token);
    await _tokenManager.saveSessionType('player');
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _api.get<Map<String, dynamic>>('/auth/player/me');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> dashboard() async {
    final res = await _api.get<Map<String, dynamic>>('/player/dashboard');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  // ── مشاركة صفحة اللاعب ──
  /// رابط صفحة اللاعب العامة (عرض فقط) — يُنشأ على الخادم إن لم يوجد.
  Future<String> myShareLink() async {
    final res = await _api.post<Map<String, dynamic>>('/player/share');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    // hash routing في نسخة الويب — نفس صيغة رابط الإدارة.
    return '${AppConstants.publicWebBaseUrl}/#/p/$token';
  }

  // ── الصورة الشخصية ──
  /// يرفع صورة اللاعب إلى Cloudinary عبر الخادم ويعيد رابط الصورة الجديد.
  Future<String?> updatePhoto(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await buildImageMultipart(imagePath, filename: 'player_image.jpg'),
    });
    final res = await _api.putMultipart<Map<String, dynamic>>(
      '/player/photo',
      data: formData,
    );
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return data?['image_url'] as String?;
  }

  /// يحذف صورة اللاعب من Cloudinary ويعيدها إلى الافتراضية.
  Future<void> deletePhoto() async {
    await _api.delete('/player/photo');
  }

  // ── طلب تجديد الاشتراك ──
  /// يرسل صورة إيصال الدفع (مطلوبة) مع ملاحظة اختيارية ليراجعها السوبر أدمن.
  Future<void> submitRenewalRequest({
    required String receiptPath,
    String? note,
  }) async {
    final formData = FormData.fromMap({
      'receipt': await buildImageMultipart(receiptPath, filename: 'receipt.jpg'),
      if (note != null && note.isNotEmpty) 'note': note,
    });
    await _api.postMultipart('/player/renewal-requests', data: formData);
  }

  // ── المحادثة ──
  Future<Map<String, dynamic>> getChat() async {
    final res = await _api.get<Map<String, dynamic>>('/player/chat');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendChat(String text) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/player/chat',
      data: {'text': text},
    );
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  // ── الإشعارات ──
  Future<void> deleteNotification(String id) async {
    await _api.delete('/player/notifications/$id');
  }

  Future<Map<String, dynamic>> notifications() async {
    final res = await _api.get<Map<String, dynamic>>('/player/notifications');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<void> markNotificationRead(String id) async {
    await _api.patch('/player/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _api.patch('/player/notifications/read-all');
  }

  Future<void> logout() async {
    await _tokenManager.clearToken();
  }
}
