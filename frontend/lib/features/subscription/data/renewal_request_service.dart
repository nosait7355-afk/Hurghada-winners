import 'package:hurghada_winners/core/network/api_client.dart';

/// طلب تجديد مُرسل من اللاعب — جهة السوبر أدمن.
class RenewalRequest {
  final String id;
  final String status;
  final String note;
  final String rejectionReason;
  final String receiptUrl;
  final DateTime createdAt;
  final String academyId;
  final String academyName;
  final String playerId;
  final String playerName;
  final String playerCode;
  final String parentPhone;
  final String? playerImageUrl;

  const RenewalRequest({
    required this.id,
    required this.status,
    required this.note,
    required this.rejectionReason,
    required this.receiptUrl,
    required this.createdAt,
    required this.academyId,
    required this.academyName,
    required this.playerId,
    required this.playerName,
    required this.playerCode,
    required this.parentPhone,
    this.playerImageUrl,
  });

  factory RenewalRequest.fromJson(Map<String, dynamic> j) => RenewalRequest(
        id: j['_id'] as String,
        status: j['status'] as String? ?? 'pending',
        note: j['note'] as String? ?? '',
        rejectionReason: j['rejectionReason'] as String? ?? '',
        receiptUrl: j['receipt_url'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
        academyId: j['academyId'] as String? ?? '',
        academyName: j['academyName'] as String? ?? '',
        playerId: j['playerId'] as String? ?? '',
        playerName: j['playerName'] as String? ?? '',
        playerCode: j['playerCode'] as String? ?? '',
        parentPhone: j['parentPhone'] as String? ?? '',
        playerImageUrl: j['playerImageUrl'] as String?,
      );
}

class RenewalRequestService {
  final ApiClient _api;
  RenewalRequestService(this._api);

  Future<List<RenewalRequest>> list(String status) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/renewal-requests',
      queryParameters: {'status': status},
    );
    final data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((e) => RenewalRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// حذف نهائي للطلب (مع صورة الإيصال).
  Future<void> delete(String id) async {
    await _api.delete('/renewal-requests/$id');
  }

  Future<int> pendingCount() async {
    final res =
        await _api.get<Map<String, dynamic>>('/renewal-requests/pending-count');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> review(String id,
      {required bool approve, String? rejectionReason}) async {
    await _api.patch('/renewal-requests/$id', data: {
      'status': approve ? 'approved' : 'rejected',
      if (!approve && rejectionReason != null) 'rejectionReason': rejectionReason,
    });
  }
}
