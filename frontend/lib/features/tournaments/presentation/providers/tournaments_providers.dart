import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/tournaments/data/tournament_models.dart';
import 'package:hurghada_winners/features/tournaments/data/tournaments_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tournamentsServiceProvider = Provider<TournamentsService>((ref) => sl<TournamentsService>());

/// بطولات فرع (academyId) — للإدارة.
final tournamentsListProvider =
    FutureProvider.autoDispose.family<List<Tournament>, String>((ref, academyId) {
  return ref.watch(tournamentsServiceProvider).list(academyId: academyId);
});

/// تفاصيل بطولة كاملة (مشاركون + مباريات + ترتيب) — للإدارة.
final tournamentDetailProvider =
    FutureProvider.autoDispose.family<TournamentDetail, String>((ref, id) {
  return ref.watch(tournamentsServiceProvider).get(id);
});

/// بوابة اللاعب.
final playerTournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) {
  return ref.watch(tournamentsServiceProvider).playerList();
});

final playerTournamentDetailProvider =
    FutureProvider.autoDispose.family<TournamentDetail, String>((ref, id) {
  return ref.watch(tournamentsServiceProvider).playerGet(id);
});
