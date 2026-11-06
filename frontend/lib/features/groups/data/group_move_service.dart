import 'package:hurghada_winners/core/network/api_client.dart';

/// نقل لاعب من مجموعة إلى أخرى عبر المسار القائم PATCH /players/:id/change-group.
/// إضافية بالكامل — تُستخدم من كل المنصات (Android / Windows / Web) بنفس الكود.
/// الخادم يتحقق من انتماء المجموعة للأكاديمية فقط (المجموعات مستقلة عن الرياضة).
class GroupMoveService {
  final ApiClient _api;
  GroupMoveService(this._api);

  /// نقل لاعب واحد إلى مجموعة. يرمي استثناءً عند الفشل (يُعرض للمستخدم).
  Future<void> changeGroup({
    required String playerId,
    required String groupId,
  }) async {
    await _api.patch<Map<String, dynamic>>(
      '/players/$playerId/change-group',
      data: {'groupId': groupId},
    );
  }

  /// نقل عدة لاعبين تسلسلياً. يعيد قائمة أخطاء (playerId → رسالة) لمن فشل نقله.
  Future<List<String>> moveMany({
    required List<String> playerIds,
    required String groupId,
  }) async {
    final errors = <String>[];
    for (final id in playerIds) {
      try {
        await changeGroup(playerId: id, groupId: groupId);
      } catch (e) {
        errors.add(e.toString());
      }
    }
    return errors;
  }
}
