import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/matches/data/match_model.dart';
import 'package:hurghada_winners/features/matches/data/matches_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════ قائمة المباريات (لكل أكاديمية) ══════════════════════

@immutable
class MatchesListState {
  final List<MatchModel> items;
  final bool loading;
  final bool loadingMore;
  final bool hasNext;
  final int page;
  final Object? error;

  const MatchesListState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasNext = false,
    this.page = 0,
    this.error,
  });

  MatchesListState copyWith({
    List<MatchModel>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasNext,
    int? page,
    Object? error,
  }) {
    return MatchesListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      error: error,
    );
  }
}

class MatchesListNotifier extends StateNotifier<MatchesListState> {
  final MatchesService _service;
  final String academyId;
  static const int _limit = 20;

  MatchesListNotifier(this._service, this.academyId) : super(const MatchesListState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const MatchesListState(loading: true);
    try {
      final res = await _service.getMatches(academyId: academyId, page: 1, limit: _limit);
      state = MatchesListState(
        items: res.items,
        loading: false,
        hasNext: res.hasNext,
        page: 1,
      );
    } catch (e) {
      state = MatchesListState(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasNext || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final res = await _service.getMatches(
        academyId: academyId,
        page: state.page + 1,
        limit: _limit,
      );
      state = state.copyWith(
        items: [...state.items, ...res.items],
        loadingMore: false,
        hasNext: res.hasNext,
        page: state.page + 1,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}

final matchesListProvider = StateNotifierProvider.autoDispose
    .family<MatchesListNotifier, MatchesListState, String>((ref, academyId) {
  return MatchesListNotifier(sl<MatchesService>(), academyId);
});

// ══════════════════════ تفاصيل مباراة واحدة ══════════════════════

@immutable
class MatchDetailState {
  final MatchModel? match;
  final List<MatchPlayer> players;
  final bool loading;
  final bool mutating;
  final Object? error;

  const MatchDetailState({
    this.match,
    this.players = const [],
    this.loading = true,
    this.mutating = false,
    this.error,
  });

  MatchDetailState copyWith({
    MatchModel? match,
    List<MatchPlayer>? players,
    bool? loading,
    bool? mutating,
    Object? error,
  }) {
    return MatchDetailState(
      match: match ?? this.match,
      players: players ?? this.players,
      loading: loading ?? this.loading,
      mutating: mutating ?? this.mutating,
      error: error,
    );
  }
}

class MatchDetailNotifier extends StateNotifier<MatchDetailState> {
  final MatchesService _service;
  final String matchId;

  MatchDetailNotifier(this._service, this.matchId) : super(const MatchDetailState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final detail = await _service.getMatch(matchId);
      state = MatchDetailState(
        match: detail.match,
        players: detail.players,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<bool> addPlayers(List<String> playerIds) async {
    state = state.copyWith(mutating: true);
    try {
      await _service.addPlayers(matchId, playerIds);
      await refresh();
      return true;
    } catch (_) {
      state = state.copyWith(mutating: false);
      return false;
    }
  }

  Future<bool> removePlayer(String playerId) async {
    state = state.copyWith(mutating: true);
    try {
      await _service.removePlayer(matchId, playerId);
      await refresh();
      return true;
    } catch (_) {
      state = state.copyWith(mutating: false);
      return false;
    }
  }

  Future<bool> logReminder(String playerId) async {
    try {
      final updated = await _service.logReminder(matchId, playerId);
      state = state.copyWith(match: updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMatch({
    String? name,
    String? location,
    String? date,
    String? time,
    String? notes,
    String? sport,
  }) async {
    state = state.copyWith(mutating: true);
    try {
      await _service.updateMatch(
        id: matchId,
        name: name,
        location: location,
        date: date,
        time: time,
        notes: notes,
        sport: sport,
      );
      await refresh();
      return true;
    } catch (_) {
      state = state.copyWith(mutating: false);
      return false;
    }
  }

  Future<bool> delete() async {
    try {
      await _service.deleteMatch(matchId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final matchDetailProvider = StateNotifierProvider.autoDispose
    .family<MatchDetailNotifier, MatchDetailState, String>((ref, matchId) {
  return MatchDetailNotifier(sl<MatchesService>(), matchId);
});
