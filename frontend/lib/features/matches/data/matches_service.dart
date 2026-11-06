import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/matches/data/match_model.dart';

/// صفحة مباريات (عناصر + معلومات الصفحات) لدعم Pagination.
class MatchPage {
  final List<MatchModel> items;
  final int total;
  final int page;
  final int totalPages;
  final bool hasNext;
  const MatchPage({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasNext,
  });
}

/// خدمة نظام المباريات — تعيد استخدام ApiClient نفسه (مطابقة StoreService).
class MatchesService {
  final ApiClient _api;
  MatchesService(this._api);

  Future<MatchPage> getMatches({
    String? academyId,
    String? sport,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/matches',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (academyId != null && academyId.isNotEmpty) 'academyId': academyId,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
      },
    );
    final body = res.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>? ?? [])
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>?;
    return MatchPage(
      items: list,
      total: (meta?['total'] as num?)?.toInt() ?? list.length,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      totalPages: (meta?['totalPages'] as num?)?.toInt() ?? 1,
      hasNext: meta?['hasNext'] as bool? ?? false,
    );
  }

  Future<MatchDetail> getMatch(String id) async {
    final res = await _api.get<Map<String, dynamic>>('/matches/$id');
    final body = res.data as Map<String, dynamic>;
    return MatchDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<MatchModel> createMatch({
    required String name,
    required String location,
    required String date,
    required String time,
    String? notes,
    String? sport,
    String? academyId,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/matches',
      data: {
        'name': name,
        'location': location,
        'date': date,
        'time': time,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
        if (academyId != null && academyId.isNotEmpty) 'academyId': academyId,
      },
    );
    return MatchModel.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<MatchModel> updateMatch({
    required String id,
    String? name,
    String? location,
    String? date,
    String? time,
    String? notes,
    String? sport,
  }) async {
    final res = await _api.put<Map<String, dynamic>>(
      '/matches/$id',
      data: {
        if (name != null) 'name': name,
        if (location != null) 'location': location,
        if (date != null) 'date': date,
        if (time != null) 'time': time,
        if (notes != null) 'notes': notes,
        if (sport != null) 'sport': sport,
      },
    );
    return MatchModel.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteMatch(String id) async {
    await _api.delete('/matches/$id');
  }

  Future<MatchModel> addPlayers(String matchId, List<String> playerIds) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/matches/$matchId/players',
      data: {'playerIds': playerIds},
    );
    return MatchModel.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<void> removePlayer(String matchId, String playerId) async {
    await _api.delete('/matches/$matchId/players/$playerId');
  }

  Future<MatchModel> logReminder(String matchId, String playerId) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/matches/$matchId/reminders/$playerId',
    );
    return MatchModel.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }
}
