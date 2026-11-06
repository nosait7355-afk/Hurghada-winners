import 'package:hurghada_winners/core/network/api_client.dart';

/// خدمة مراجعة طلبات الانضمام الذاتي للاعبين (تسجيل ذاتي من شاشة دخول
/// اللاعب). إضافية بالكامل — لا تمسّ أي مسار أو Provider قائم.
class JoinRequestService {
  final ApiClient _api;
  JoinRequestService(this._api);

  /// قائمة طلبات الانضمام لأكاديمية معيّنة.
  /// [status] إمّا 'pending' (الافتراضي) أو 'rejected'.
  Future<List<Map<String, dynamic>>> list({
    String? academyId,
    String status = 'pending',
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/players/join-requests',
      queryParameters: {
        if (academyId != null) 'academyId': academyId,
        'status': status,
      },
    );
    final data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// تفاصيل طلب انضمام (وثيقة اللاعب كاملة — تشمل receipt_url وbranch).
  Future<Map<String, dynamic>> getDetail(String playerId) async {
    final res = await _api.get<Map<String, dynamic>>('/players/$playerId');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  /// تعديل بيانات الطلب قبل الموافقة (نفس endpoint تعديل اللاعب العادي).
  Future<void> updateFields(String playerId, Map<String, dynamic> fields) async {
    await _api.put<Map<String, dynamic>>('/players/$playerId', data: fields);
  }

  /// موافقة على الطلب: يحدّد الأدمن مبلغ وتاريخ الاشتراك، فيُنشأ الاشتراك
  /// ويُفعَّل الحساب دفعة واحدة.
  Future<void> approve(
    String playerId, {
    required double amount,
    required String startDate, // yyyy-MM-dd
    required String endDate,
    String? notes,
  }) async {
    await _api.patch<Map<String, dynamic>>(
      '/players/$playerId/approve-join-request',
      data: {
        'amount': amount,
        'startDate': startDate,
        'endDate': endDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  /// رفض الطلب (السجل يبقى محفوظاً بحالة "مرفوض" للأرشيف).
  Future<void> reject(String playerId, {String? reason}) async {
    await _api.patch<Map<String, dynamic>>(
      '/players/$playerId/reject-join-request',
      data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
  }

  /// حذف نهائي لطلب مرفوض (اللاعب + حسابه + صوره) — لا يظهر بعدها في أي مكان.
  Future<void> deleteRejected(String playerId) async {
    await _api.delete<Map<String, dynamic>>('/players/$playerId/join-request');
  }
}
