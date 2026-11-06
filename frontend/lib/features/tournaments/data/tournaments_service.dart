import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/tournaments/data/tournament_models.dart';

/// لاعب مختصر لشاشة اختيار لاعبي البطولة.
class PickablePlayer {
  final String id;
  final String fullName;
  final String playerCode;
  final String academyId;
  const PickablePlayer({required this.id, required this.fullName, required this.playerCode, required this.academyId});
}

/// خدمة البطولات — /api/v1/tournaments (إدارة) و /api/v1/player/tournaments (بوابة اللاعب).
class TournamentsService {
  final ApiClient _api;
  TournamentsService(this._api);

  Map<String, dynamic> _data(dynamic res) => (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  Future<List<Tournament>> list({String? academyId}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/tournaments',
      queryParameters: {if (academyId != null && academyId.isNotEmpty) 'academyId': academyId},
    );
    return ((res.data as Map<String, dynamic>)['data'] as List? ?? [])
        .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentDetail> get(String id) async =>
      TournamentDetail.fromJson(_data(await _api.get<Map<String, dynamic>>('/tournaments/$id')));

  Future<Tournament> create(Map<String, dynamic> body) async =>
      Tournament.fromJson(_data(await _api.post<Map<String, dynamic>>('/tournaments', data: body)));

  Future<Tournament> update(String id, Map<String, dynamic> body) async =>
      Tournament.fromJson(_data(await _api.put<Map<String, dynamic>>('/tournaments/$id', data: body)));

  Future<void> delete(String id) => _api.delete('/tournaments/$id');

  Future<void> addParticipant(String id, {String? name, required List<String> playerIds, String? captainId}) =>
      _api.post('/tournaments/$id/participants', data: {
        if (name != null) 'name': name,
        'playerIds': playerIds,
        if (captainId != null) 'captainId': captainId,
      });

  Future<void> updateParticipant(String id, String participantId,
          {String? name, List<String>? playerIds, String? captainId}) =>
      _api.put('/tournaments/$id/participants/$participantId', data: {
        if (name != null) 'name': name,
        if (playerIds != null) 'playerIds': playerIds,
        'captainId': captainId,
      });

  Future<void> removeParticipant(String id, String participantId) =>
      _api.delete('/tournaments/$id/participants/$participantId');

  Future<void> orderParticipants(String id, List<String> order) =>
      _api.put('/tournaments/$id/participants/order', data: {'order': order});

  Future<void> generate(String id) => _api.post('/tournaments/$id/generate');

  Future<void> resetFixtures(String id) => _api.delete('/tournaments/$id/fixtures');

  Future<void> updateFixture(String id, String fixtureId, Map<String, dynamic> body) =>
      _api.put('/tournaments/$id/fixtures/$fixtureId', data: body);

  Future<void> recordResult(String id, String fixtureId, Map<String, dynamic> body) =>
      _api.post('/tournaments/$id/fixtures/$fixtureId/result', data: body);

  Future<void> clearResult(String id, String fixtureId) =>
      _api.delete('/tournaments/$id/fixtures/$fixtureId/result');

  /// لاعبو فرع معيّن (للاختيار في الفرق) — بحث بالاسم أو الكود.
  Future<List<PickablePlayer>> searchPlayers({required String academyId, String search = ''}) async {
    final res = await _api.get<Map<String, dynamic>>('/players', queryParameters: {
      'academyId': academyId,
      'limit': 100,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });
    return ((res.data as Map<String, dynamic>)['data'] as List? ?? []).map((e) {
      final j = e as Map<String, dynamic>;
      return PickablePlayer(
        id: (j['_id'] ?? j['id']).toString(),
        fullName: j['fullName']?.toString() ?? '',
        playerCode: j['playerCode']?.toString() ?? '',
        academyId: j['academyId']?.toString() ?? academyId,
      );
    }).toList();
  }

  // ── بوابة اللاعب ──
  Future<List<Tournament>> playerList() async {
    final res = await _api.get<Map<String, dynamic>>('/player/tournaments');
    return ((res.data as Map<String, dynamic>)['data'] as List? ?? [])
        .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentDetail> playerGet(String id) async =>
      TournamentDetail.fromJson(_data(await _api.get<Map<String, dynamic>>('/player/tournaments/$id')));
}
