import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/team_kit/data/kit_booking.dart';
import 'package:hurghada_winners/features/team_kit/data/team_kit.dart';
import 'package:hurghada_winners/features/team_kit/data/team_kit_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════ الطقم — جهة المدير ══════════════════════

@immutable
class KitState {
  final TeamKit? kit;
  final bool loading;
  final Object? error;

  const KitState({this.kit, this.loading = true, this.error});

  KitState copyWith({TeamKit? kit, bool? loading, Object? error, bool clearKit = false}) {
    return KitState(
      kit: clearKit ? null : (kit ?? this.kit),
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class KitNotifier extends StateNotifier<KitState> {
  final TeamKitService _service;
  final String? _academyId;

  KitNotifier(this._service, this._academyId) : super(const KitState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const KitState(loading: true);
    try {
      final kit = await _service.getKit(academyId: _academyId);
      state = KitState(kit: kit, loading: false);
    } catch (e) {
      state = KitState(loading: false, error: e);
    }
  }

  Future<void> save({
    String? imagePath,
    required String name,
    required double price,
    required List<String> availableSizes,
  }) async {
    final kit = await _service.saveKit(
      imagePath: imagePath,
      name: name,
      price: price,
      availableSizes: availableSizes,
      academyId: _academyId,
    );
    state = state.copyWith(kit: kit);
  }

  Future<void> deleteKit() async {
    await _service.deleteKit(academyId: _academyId);
    state = state.copyWith(clearKit: true);
  }
}

/// [academyId]: انظر توضيح storeProductsProvider في متجر الأكاديمية — نفس النمط.
final teamKitProvider = StateNotifierProvider.autoDispose
    .family<KitNotifier, KitState, String?>((ref, academyId) {
  return KitNotifier(sl<TeamKitService>(), academyId);
});

// ══════════════════════ الطقم — جهة اللاعب ══════════════════════

final playerKitProvider =
    FutureProvider.autoDispose<TeamKit?>((ref) async {
  return sl<TeamKitService>().getPlayerKit();
});

// ══════════════════════ الحجوزات — جهة المدير ══════════════════════

@immutable
class KitBookingsState {
  final List<KitBooking> items;
  final bool loading;
  final bool loadingMore;
  final bool hasNext;
  final int page;
  final int pendingCount;
  final String? statusFilter;

  /// فرز بالمقاس (تبويب المعتمدة) — null = الكل.
  final String? sizeFilter;
  final Map<String, int> sizeCounts;
  final Object? error;

  const KitBookingsState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasNext = false,
    this.page = 0,
    this.pendingCount = 0,
    this.statusFilter,
    this.sizeFilter,
    this.sizeCounts = const {},
    this.error,
  });

  KitBookingsState copyWith({
    List<KitBooking>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasNext,
    int? page,
    int? pendingCount,
    String? statusFilter,
    bool clearFilter = false,
    String? sizeFilter,
    bool clearSize = false,
    Map<String, int>? sizeCounts,
    Object? error,
  }) {
    return KitBookingsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      pendingCount: pendingCount ?? this.pendingCount,
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
      sizeFilter: clearSize ? null : (sizeFilter ?? this.sizeFilter),
      sizeCounts: sizeCounts ?? this.sizeCounts,
      error: error,
    );
  }
}

class KitBookingsNotifier extends StateNotifier<KitBookingsState> {
  final TeamKitService _service;
  final String? _academyId;
  static const int _limit = 20;

  KitBookingsNotifier(this._service, this._academyId, {String? initialFilter})
      : super(KitBookingsState(statusFilter: initialFilter)) {
    refresh();
  }

  Future<void> setFilter(String? status) async {
    // تغيير التبويب يلغي فرز المقاس.
    state = state.copyWith(
        statusFilter: status, clearFilter: status == null, clearSize: true);
    await refresh();
  }

  Future<void> setSize(String? size) async {
    state = state.copyWith(sizeFilter: size, clearSize: size == null);
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, items: [], page: 0);
    try {
      final res = await _service.getBookings(
        page: 1,
        limit: _limit,
        status: state.statusFilter,
        size: state.sizeFilter,
        academyId: _academyId,
      );
      state = state.copyWith(
        items: res.items,
        loading: false,
        hasNext: res.hasNext,
        page: 1,
        pendingCount: res.pendingCount,
        sizeCounts: res.sizeCounts,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasNext || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final res = await _service.getBookings(
        page: state.page + 1,
        limit: _limit,
        status: state.statusFilter,
        size: state.sizeFilter,
        academyId: _academyId,
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

/// [academyId]: انظر توضيح storeOrdersProvider في متجر الأكاديمية — نفس النمط.
final kitBookingsProvider = StateNotifierProvider.autoDispose
    .family<KitBookingsNotifier, KitBookingsState, String?>((ref, academyId) {
  return KitBookingsNotifier(sl<TeamKitService>(), academyId,
      initialFilter: 'pending_review');
});
