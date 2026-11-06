import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/notification/data/notification_alerts_service.dart';
import 'package:hurghada_winners/features/notification/domain/entities/notification_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تنبيهات الإدارة — تُحسب على الخادم لكل اللاعبين (كل الفروع للسوبر أدمن)،
/// وحالة القراءة/الإخفاء محفوظة على الخادم: ما يُخفى من الموبايل يختفي من
/// الكمبيوتر أيضاً.
class NotificationNotifier extends AsyncNotifier<List<NotificationEntity>> {
  // مفاتيح الحالة القديمة المحفوظة على الجهاز — تُرحَّل للخادم مرة واحدة.
  static const _legacyReadKey = 'notification_read_ids';
  static const _legacyDeletedKey = 'notification_deleted_ids';
  static const _cacheDuration = Duration(minutes: 5);

  List<NotificationEntity>? _cache;
  DateTime? _cacheTime;
  String? _cacheUserId;

  NotificationAlertsService get _service => sl<NotificationAlertsService>();

  @override
  Future<List<NotificationEntity>> build() async {
    // نراقب معرّف المستخدم فقط — لا كامل AuthState — حتى لا نعيد البناء مع
    // isLoading / errorMessage.
    final userId = ref.watch(
      authStateProvider.select((s) => s.valueOrNull?.user?.id),
    );

    if (userId == null) {
      _cache = null;
      _cacheTime = null;
      _cacheUserId = null;
      return [];
    }

    if (_cache != null &&
        _cacheUserId == userId &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache!;
    }

    final user = ref.read(authStateProvider).valueOrNull?.user;
    if (user == null) return [];
    return _load(user);
  }

  Future<List<NotificationEntity>> _load(UserEntity user) async {
    await _migrateLegacyState();
    final items = await _service.fetch(
      academyId: user.isSuperAdmin ? 'all' : null,
    );
    _cache = items;
    _cacheTime = DateTime.now();
    _cacheUserId = user.id;
    return items;
  }

  /// يرحّل ما قُرئ/حُذف سابقاً على هذا الجهاز إلى الخادم ثم يمسحه — نفس صيغة
  /// المعرّفات، فلا يعود ظهور ما أخفاه المستخدم قبل التحديث.
  Future<void> _migrateLegacyState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = prefs.getStringList(_legacyReadKey) ?? const [];
      final deleted = prefs.getStringList(_legacyDeletedKey) ?? const [];
      if (read.isEmpty && deleted.isEmpty) return;
      await _service.updateState(read, read: true);
      await _service.updateState(deleted, dismissed: true);
      await prefs.remove(_legacyReadKey);
      await prefs.remove(_legacyDeletedKey);
    } catch (_) {
      // نعيد المحاولة في التحميل القادم.
    }
  }

  void _setLocal(List<NotificationEntity> list) {
    _cache = list;
    state = AsyncValue.data(list);
  }

  Future<void> refresh() async {
    _cache = null;
    _cacheTime = null;
    final user = ref.read(authStateProvider).valueOrNull?.user;
    if (user == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(user));
  }

  Future<void> markAsRead(String id) async {
    final current = state.valueOrNull ?? [];
    _setLocal(
        current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList());
    try {
      await _service.updateState([id], read: true);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final current = state.valueOrNull ?? [];
    _setLocal(current.map((n) => n.copyWith(isRead: true)).toList());
    try {
      await _service.updateState(
        current.where((n) => !n.isRead).map((n) => n.id).toList(),
        read: true,
      );
    } catch (_) {}
  }

  /// إخفاء نهائي — لا يظهر مرة أخرى على أي جهاز.
  Future<void> deleteNotification(String id) async {
    final current = state.valueOrNull ?? [];
    _setLocal(current.where((n) => n.id != id).toList());
    try {
      await _service.updateState([id], dismissed: true);
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    final current = state.valueOrNull ?? [];
    _setLocal(const []);
    try {
      await _service.updateState(current.map((n) => n.id).toList(),
          dismissed: true);
    } catch (_) {}
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, List<NotificationEntity>>(
  NotificationNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationProvider).valueOrNull ?? [];
  return list.where((n) => !n.isRead).length;
});
