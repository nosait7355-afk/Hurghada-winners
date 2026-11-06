import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/notification/domain/entities/notification_entity.dart';

/// تنبيهات الإدارة المحسوبة على الخادم (أعياد ميلاد، تذكير اشتراك، طلبات
/// انضمام، غياب متكرر) + حفظ حالة القراءة/الإخفاء لكل مستخدم على كل أجهزته.
class NotificationAlertsService {
  final ApiClient _api;
  NotificationAlertsService(this._api);

  static String _today() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static NotificationType _type(String? t) => switch (t) {
        'birthday' => NotificationType.birthday,
        'subscriptionExpiring' => NotificationType.subscriptionExpiring,
        'subscriptionExpired' => NotificationType.subscriptionExpired,
        'joinRequest' => NotificationType.joinRequest,
        'absence' => NotificationType.absence,
        _ => NotificationType.system,
      };

  /// [academyId]: للسوبر أدمن 'all' (كل الفروع) أو فرع محدد؛ غيره يتجاهله الخادم.
  Future<List<NotificationEntity>> fetch({String? academyId}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/notifications/alerts',
      queryParameters: {
        'localDate': _today(),
        if (academyId != null) 'academyId': academyId,
      },
    );
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ((data['items'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((j) => NotificationEntity(
              id: j['id'] as String,
              type: _type(j['type'] as String?),
              title: j['title'] as String? ?? '',
              body: j['body'] as String? ?? '',
              createdAt:
                  DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ??
                      DateTime.now(),
              isRead: j['isRead'] == true,
              playerId: j['playerId'] as String?,
              parentPhone: j['parentPhone'] as String?,
              playerName: j['playerName'] as String?,
              academyName: j['academyName'] as String?,
              academyId: j['academyId'] as String?,
              subscriptionEndDate: DateTime.tryParse(
                      j['subscriptionEndDate'] as String? ?? '')
                  ?.toLocal(),
              absentCount: (j['absentCount'] as num?)?.toInt(),
            ))
        .toList();
  }

  /// تعليم تنبيهات كمقروءة و/أو إخفاؤها نهائياً (لهذا المستخدم).
  Future<void> updateState(List<String> ids,
      {bool read = false, bool dismissed = false}) async {
    if (ids.isEmpty) return;
    await _api.post<Map<String, dynamic>>(
      '/notifications/alerts/state',
      data: {
        'ids': ids,
        if (read) 'read': true,
        if (dismissed) 'dismissed': true,
      },
    );
  }
}
