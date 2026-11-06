import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/player_portal/data/player_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// لوحة اللاعب المجمّعة (جدول/حضور/اشتراك/تقييمات/إشعارات).
final playerDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return sl<PlayerApiService>().dashboard();
});

/// باقي حسابات العائلة — فارغة إن لم يكن الحساب ضمن عائلة (يُخفى زر التبديل).
final playerFamilyProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    return await sl<PlayerApiService>().family();
  } catch (_) {
    return const [];
  }
});

/// إشعارات اللاعب (قائمة + عدد غير مقروء).
final playerNotificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return sl<PlayerApiService>().notifications();
});
