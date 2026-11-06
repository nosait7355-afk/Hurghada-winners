import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/chat/data/chat_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// قائمة محادثات الأكاديمية (جهة المدير).
final academyConversationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return sl<ChatApiService>().getConversations();
});

/// عدّاد رسائل المدير غير المقروءة — مجموع unread عبر كل المحادثات.
/// مشتق من نفس قائمة المحادثات (لا endpoint إضافي)، ومستقل تماماً عن عدّاد
/// مركز الإشعارات (unreadCountProvider). يُصفَّر عند فتح محادثة لأن الخادم
/// يصفّر unreadForAcademy ثم نُبطل القائمة.
final academyMessagesUnreadProvider = Provider.autoDispose<int>((ref) {
  final convos = ref.watch(academyConversationsProvider).valueOrNull ?? [];
  var total = 0;
  for (final c in convos) {
    total += (c['unread'] as num?)?.toInt() ?? 0;
  }
  return total;
});
