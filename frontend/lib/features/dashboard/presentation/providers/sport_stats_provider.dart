import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One recent player inside a sport's stats payload.
class SportRecentPlayer {
  final String id;
  final String playerCode;
  final String fullName;
  final String? imageUrl;

  const SportRecentPlayer({
    required this.id,
    required this.playerCode,
    required this.fullName,
    this.imageUrl,
  });

  factory SportRecentPlayer.fromJson(Map<String, dynamic> json) {
    return SportRecentPlayer(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      playerCode: (json['playerCode'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }
}

/// Per-sport dashboard statistics.
class SportStats {
  final String sport;
  final int totalPlayers;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final double revenue;
  final List<SportRecentPlayer> recentPlayers;

  const SportStats({
    required this.sport,
    required this.totalPlayers,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.revenue,
    required this.recentPlayers,
  });

  factory SportStats.fromJson(Map<String, dynamic> json) {
    return SportStats(
      sport: (json['sport'] as String?) ?? '',
      totalPlayers: (json['totalPlayers'] as num?)?.toInt() ?? 0,
      activeSubscriptions: (json['activeSubscriptions'] as num?)?.toInt() ?? 0,
      expiredSubscriptions: (json['expiredSubscriptions'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      recentPlayers: ((json['recentPlayers'] as List<dynamic>?) ?? [])
          .map((e) => SportRecentPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Parameter for [sportStatsProvider]: which academy + which sport.
class SportStatsParams {
  final String academyId;
  final String sport;
  const SportStatsParams({required this.academyId, required this.sport});

  @override
  bool operator ==(Object other) =>
      other is SportStatsParams &&
      other.academyId == academyId &&
      other.sport == sport;

  @override
  int get hashCode => Object.hash(academyId, sport);
}

/// Fetches per-sport stats from `GET /dashboard/sport-stats` in one request.
final sportStatsProvider =
    FutureProvider.family<SportStats, SportStatsParams>((ref, params) async {
  final api = sl<ApiClient>();
  final response = await api.get(
    '/dashboard/sport-stats',
    queryParameters: {
      'academyId': params.academyId,
      'sport': params.sport,
    },
  );
  final body = response.data as Map<String, dynamic>;
  return SportStats.fromJson(body['data'] as Map<String, dynamic>);
});
