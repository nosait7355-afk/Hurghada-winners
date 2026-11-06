import 'package:hurghada_winners/core/network/api_client.dart';

/// خدمة محادثات جهة الأكاديمية (نص فقط).
class ChatApiService {
  final ApiClient _api;
  ChatApiService(this._api);

  Future<List<Map<String, dynamic>>> getConversations() async {
    final res = await _api.get<Map<String, dynamic>>('/chat/conversations');
    final data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getMessages(String playerId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/chat/conversations/$playerId/messages',
    );
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage(String playerId, String text) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/chat/conversations/$playerId/messages',
      data: {'text': text},
    );
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }
}
