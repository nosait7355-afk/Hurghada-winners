import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_players_usecase.dart';

/// Returns the set of player ids matching the [sport] and/or [groupId] scope
/// within [academyId], fetched in a SINGLE query (no per-filter requests).
///
/// Sport and Group are INDEPENDENT dimensions — passing both returns the
/// intersection (e.g. "Basketball players inside Group A"). Returns `null`
/// when neither sport nor group is set, meaning "all academy players" —
/// callers then skip filtering entirely. Used by the PDF and Excel report
/// services to scope subscriptions / evaluations / revenue by player id.
Future<Set<String>?> playerIdsForSport(
  String? academyId,
  String? sport, [
  String? groupId,
]) async {
  final hasSport = sport != null && sport.isNotEmpty;
  final hasGroup = groupId != null && groupId.isNotEmpty;
  if (academyId == null || (!hasSport && !hasGroup)) return null;
  final res = await sl<GetPlayersUsecase>()(
    GetPlayersParams(
      academyId: academyId,
      sport: hasSport ? sport : null,
      groupId: hasGroup ? groupId : null,
      page: 1,
      limit: 500,
    ),
  );
  return res.fold(
    (_) => <String>{},
    (r) => r.players.map((p) => p.id).toSet(),
  );
}
