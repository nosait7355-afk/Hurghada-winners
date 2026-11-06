import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/domain/usecases/create_player_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/delete_player_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_player_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_players_birthdays_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_players_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/search_players_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/update_player_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// PlayersState
// ---------------------------------------------------------------------------

class PlayersState {
  final List<PlayerEntity> players;
  final int total;
  final int page;
  final int totalPages;
  final bool hasMore;
  final String? search;
  final int? birthYearFilter;
  final String? academyIdFilter;
  final String? sportFilter;
  final String? attendanceDayFilter;

  /// فلتر حساب اللاعب: true = لديهم حساب، false = بدون حساب، null = الكل.
  final bool? hasAccountFilter;
  final String? groupFilter;

  const PlayersState({
    this.players = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.search,
    this.birthYearFilter,
    this.academyIdFilter,
    this.sportFilter,
    this.attendanceDayFilter,
    this.hasAccountFilter,
    this.groupFilter,
  });

  PlayersState copyWith({
    List<PlayerEntity>? players,
    int? total,
    int? page,
    int? totalPages,
    bool? hasMore,
    Object? search = _sentinel,
    Object? birthYearFilter = _sentinel,
    Object? academyIdFilter = _sentinel,
    Object? sportFilter = _sentinel,
    Object? attendanceDayFilter = _sentinel,
    Object? hasAccountFilter = _sentinel,
    Object? groupFilter = _sentinel,
  }) {
    return PlayersState(
      players: players ?? this.players,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      search: search == _sentinel ? this.search : search as String?,
      birthYearFilter: birthYearFilter == _sentinel
          ? this.birthYearFilter
          : birthYearFilter as int?,
      academyIdFilter: academyIdFilter == _sentinel
          ? this.academyIdFilter
          : academyIdFilter as String?,
      sportFilter:
          sportFilter == _sentinel ? this.sportFilter : sportFilter as String?,
      attendanceDayFilter: attendanceDayFilter == _sentinel
          ? this.attendanceDayFilter
          : attendanceDayFilter as String?,
      hasAccountFilter: hasAccountFilter == _sentinel
          ? this.hasAccountFilter
          : hasAccountFilter as bool?,
      groupFilter:
          groupFilter == _sentinel ? this.groupFilter : groupFilter as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// PlayersNotifier
// ---------------------------------------------------------------------------

class PlayersNotifier extends AsyncNotifier<PlayersState> {
  // getter (لا late final): build() يُعاد تشغيله عند التحديث على نفس الكائن.
  GetPlayersUsecase get _getPlayersUsecase => sl<GetPlayersUsecase>();
  CreatePlayerUsecase get _createPlayerUsecase => sl<CreatePlayerUsecase>();
  UpdatePlayerUsecase get _updatePlayerUsecase => sl<UpdatePlayerUsecase>();
  DeletePlayerUsecase get _deletePlayerUsecase => sl<DeletePlayerUsecase>();

  @override
  Future<PlayersState> build() async {
    // Do NOT fetch on build — academy context is required.
    // PlayersListScreen.initState calls openForAcademy() which triggers the first load.
    return const PlayersState();
  }

  Future<PlayersState> _fetchPlayers({
    String? search,
    int? birthYearFilter,
    String? academyIdFilter,
    String? sportFilter,
    String? attendanceDayFilter,
    bool? hasAccountFilter,
    String? groupFilter,
    int page = 1,
    int limit = 50,
  }) async {
    final result = await _getPlayersUsecase(
      GetPlayersParams(
        search: search,
        birthYear: birthYearFilter,
        academyId: academyIdFilter,
        sport: sportFilter,
        attendanceDay: attendanceDayFilter,
        hasAccount: hasAccountFilter,
        groupId: groupFilter,
        page: page,
        limit: limit,
      ),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => PlayersState(
        players: data.players,
        total: data.total,
        page: data.page,
        totalPages: data.totalPages,
        hasMore: data.page < data.totalPages,
        search: search,
        birthYearFilter: birthYearFilter,
        academyIdFilter: academyIdFilter,
        sportFilter: sportFilter,
        attendanceDayFilter: attendanceDayFilter,
        hasAccountFilter: hasAccountFilter,
        groupFilter: groupFilter,
      ),
    );
  }

  /// فتح قائمة لاعبي فرع من جديد بلا أي فلاتر متبقية.
  /// هذا الـ provider مشترك (قائمة اللاعبين + اختيار لاعبي المباراة)؛ بدون
  /// التصفير يبقى بحث/مجموعة من شاشة سابقة مطبّقاً بصمت ← قائمة فارغة.
  Future<void> openForAcademy(String academyId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPlayers(academyIdFilter: academyId));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
        hasAccountFilter: current?.hasAccountFilter,
        groupFilter: current?.groupFilter,
      ),
    );
  }

  Future<void> search(String query) async {
    // Capture current filters BEFORE switching to loading —
    // AsyncLoading() clears valueOrNull, otherwise academy/year filters are lost.
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: query.isEmpty ? null : query,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
        hasAccountFilter: current?.hasAccountFilter,
        groupFilter: current?.groupFilter,
      ),
    );
  }

  Future<void> clearSearch() async {
    // Remove the search term entirely and reload the full list,
    // preserving academy and birth-year filters.
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: null,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
        hasAccountFilter: current?.hasAccountFilter,
        groupFilter: current?.groupFilter,
      ),
    );
  }

  Future<void> filterByBirthYear(int? year) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: year,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
        hasAccountFilter: current?.hasAccountFilter,
        groupFilter: current?.groupFilter,
      ),
    );
  }

  Future<void> filterByAcademy(String? academyId) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: academyId,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
        hasAccountFilter: current?.hasAccountFilter,
        // المجموعة تخص فرعاً واحداً — تغيير الفرع يلغيها وإلا تظهر القائمة فارغة.
        groupFilter: academyId == current?.academyIdFilter ? current?.groupFilter : null,
      ),
    );
  }

  Future<void> filterBySport(String? sport) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: sport,
        attendanceDayFilter: current?.attendanceDayFilter,
        hasAccountFilter: current?.hasAccountFilter,
        groupFilter: current?.groupFilter,
      ),
    );
  }

  Future<void> filterByAttendanceDay(String? day) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: day,
        hasAccountFilter: current?.hasAccountFilter,
        groupFilter: current?.groupFilter,
      ),
    );
  }

  Future<void> filterByAccount(bool? hasAccount) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
        hasAccountFilter: hasAccount,
        groupFilter: current?.groupFilter,
      ),
    );
  }

  Future<void> filterByGroup(String? groupId) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
        sportFilter: current?.sportFilter,
        attendanceDayFilter: current?.attendanceDayFilter,
        hasAccountFilter: current?.hasAccountFilter,
        groupFilter: groupId,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    final nextPage = current.page + 1;
    final result = await _getPlayersUsecase(
      GetPlayersParams(
        search: current.search,
        birthYear: current.birthYearFilter,
        academyId: current.academyIdFilter,
        sport: current.sportFilter,
        attendanceDay: current.attendanceDayFilter,
        hasAccount: current.hasAccountFilter,
        groupId: current.groupFilter,
        page: nextPage,
        limit: 50,
      ),
    );
    result.fold(
      (_) {},
      (data) {
        state = AsyncValue.data(
          current.copyWith(
            players: [...current.players, ...data.players],
            page: data.page,
            totalPages: data.totalPages,
            total: data.total,
            hasMore: data.page < data.totalPages,
          ),
        );
      },
    );
  }

  Future<String?> createPlayer({
    required String fullName,
    required DateTime birthDate,
    required String parentName,
    required String parentRelationship,
    String? parentJob,
    required String parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String> attendanceDays = const [],
    String? academyId,
    required String imagePath,
    required String receiptPath,
    String? groupId,
  }) async {
    final result = await _createPlayerUsecase(
      CreatePlayerParams(
        fullName: fullName,
        birthDate: birthDate,
        parentName: parentName,
        parentRelationship: parentRelationship,
        parentJob: parentJob,
        parentPhone: parentPhone,
        playerPhone: playerPhone,
        notes: notes,
        sport: sport,
        attendanceDays: attendanceDays,
        academyId: academyId,
        imagePath: imagePath,
        receiptPath: receiptPath,
        groupId: groupId,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> updatePlayer({
    required String id,
    String? fullName,
    DateTime? birthDate,
    String? parentName,
    String? parentRelationship,
    String? parentJob,
    String? parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String>? attendanceDays,
    String? imagePath,
    String? groupId,
  }) async {
    final result = await _updatePlayerUsecase(
      UpdatePlayerParams(
        id: id,
        fullName: fullName,
        birthDate: birthDate,
        parentName: parentName,
        parentRelationship: parentRelationship,
        parentJob: parentJob,
        parentPhone: parentPhone,
        playerPhone: playerPhone,
        notes: notes,
        sport: sport,
        attendanceDays: attendanceDays,
        imagePath: imagePath,
        groupId: groupId,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        ref.invalidate(playerByIdProvider(id));
        refresh();
        return null;
      },
    );
  }

  Future<String?> deletePlayer(String id) async {
    final result = await _deletePlayerUsecase(
      DeletePlayerParams(id: id),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        ref.invalidate(playerByIdProvider(id));
        refresh();
        return null;
      },
    );
  }
}

/// لاعب واحد بمعرّفه من الخادم. صفحة اللاعب تُفتح من شاشات كثيرة (اشتراكات،
/// إشعارات، مجموعات، تجديدات...) فلا يصح أن تعتمد على الصفحة المحمّلة حالياً
/// من قائمة اللاعبين — وإلا ظهر "اللاعب غير موجود" لأي لاعب خارجها.
final playerByIdProvider =
    FutureProvider.autoDispose.family<PlayerEntity, String>((ref, id) async {
  final result = await sl<GetPlayerUsecase>()(GetPlayerParams(id: id));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (player) => player,
  );
});

final playersProvider =
    AsyncNotifierProvider<PlayersNotifier, PlayersState>(PlayersNotifier.new);

// ---------------------------------------------------------------------------
// PlayerSearchNotifier
// ---------------------------------------------------------------------------

class PlayerSearchNotifier extends AsyncNotifier<List<PlayerEntity>> {
  // getter (لا late final): build() يُعاد تشغيله عند التحديث على نفس الكائن.
  SearchPlayersUsecase get _searchPlayersUsecase => sl<SearchPlayersUsecase>();

  @override
  Future<List<PlayerEntity>> build() async {
    return [];
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _searchPlayersUsecase(
        SearchPlayersParams(query: query.trim()),
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (players) => players,
      );
    });
  }

  Future<void> clear() async {
    state = const AsyncValue.data([]);
  }
}

final playerSearchProvider =
    AsyncNotifierProvider<PlayerSearchNotifier, List<PlayerEntity>>(
  PlayerSearchNotifier.new,
);

// ---------------------------------------------------------------------------
// Player Birthdays — لاعبو الأكاديمية اللي عيد ميلادهم في الشهر الحالي.
// ---------------------------------------------------------------------------

/// أعياد ميلاد شهر محدد (1..12) — المفتاح (academyId, month).
final playerBirthdaysProvider = FutureProvider.family<List<PlayerEntity>,
    ({String academyId, int month})>((ref, key) async {
  final usecase = sl<GetPlayersBirthdaysUsecase>();
  final result = await usecase(
    GetPlayersBirthdaysParams(
      month: key.month,
      academyId: key.academyId,
    ),
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (players) => players,
  );
});
