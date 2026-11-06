import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/store/data/store_order.dart';
import 'package:hurghada_winners/features/store/data/store_product.dart';
import 'package:hurghada_winners/features/store/data/store_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════ متجر (منتجات) — جهة المدير ══════════════════════

@immutable
class ProductsState {
  final List<StoreProduct> items;
  final bool loading;
  final bool loadingMore;
  final bool hasNext;
  final int page;
  final Object? error;

  const ProductsState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasNext = false,
    this.page = 0,
    this.error,
  });

  ProductsState copyWith({
    List<StoreProduct>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasNext,
    int? page,
    Object? error,
  }) {
    return ProductsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      error: error,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final StoreService _service;
  final String? _academyId;
  static const int _limit = 20;

  ProductsNotifier(this._service, this._academyId) : super(const ProductsState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const ProductsState(loading: true);
    try {
      final res =
          await _service.getProducts(page: 1, limit: _limit, academyId: _academyId);
      state = ProductsState(
        items: res.items,
        loading: false,
        hasNext: res.hasNext,
        page: 1,
      );
    } catch (e) {
      state = ProductsState(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasNext || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final res = await _service.getProducts(
          page: state.page + 1, limit: _limit, academyId: _academyId);
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

/// [academyId]: أكاديمية اللاعب/المدير الحالية، أو الأكاديمية التي يتصرف
/// كها super_admin (null لأدوار أخرى تعتمد على أكاديمية التوكن مباشرة).
final storeProductsProvider = StateNotifierProvider.autoDispose
    .family<ProductsNotifier, ProductsState, String?>((ref, academyId) {
  return ProductsNotifier(sl<StoreService>(), academyId);
});

// ══════════════════════ متجر (منتجات) — جهة اللاعب ══════════════════════

@immutable
class PlayerStoreState {
  final List<StoreProduct> items;
  final bool loading;
  final bool loadingMore;
  final bool hasNext;
  final int page;
  final String academyName;
  final String whatsApp;
  final String currency;
  final Object? error;

  const PlayerStoreState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasNext = false,
    this.page = 0,
    this.academyName = '',
    this.whatsApp = '',
    this.currency = 'EGP',
    this.error,
  });

  PlayerStoreState copyWith({
    List<StoreProduct>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasNext,
    int? page,
    String? academyName,
    String? whatsApp,
    String? currency,
    Object? error,
  }) {
    return PlayerStoreState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      academyName: academyName ?? this.academyName,
      whatsApp: whatsApp ?? this.whatsApp,
      currency: currency ?? this.currency,
      error: error,
    );
  }
}

class PlayerStoreNotifier extends StateNotifier<PlayerStoreState> {
  final StoreService _service;
  static const int _limit = 20;

  PlayerStoreNotifier(this._service) : super(const PlayerStoreState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const PlayerStoreState(loading: true);
    try {
      final res = await _service.getPlayerStore(page: 1, limit: _limit);
      state = PlayerStoreState(
        items: res.items,
        loading: false,
        hasNext: res.hasNext,
        page: 1,
        academyName: res.academyName,
        whatsApp: res.whatsApp,
        currency: res.currency,
      );
    } catch (e) {
      state = PlayerStoreState(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasNext || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final res = await _service.getPlayerStore(page: state.page + 1, limit: _limit);
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

final playerStoreProvider =
    StateNotifierProvider.autoDispose<PlayerStoreNotifier, PlayerStoreState>((ref) {
  return PlayerStoreNotifier(sl<StoreService>());
});

// ══════════════════════ الطلبات — جهة المدير ══════════════════════

@immutable
class OrdersState {
  final List<StoreOrder> items;
  final bool loading;
  final bool loadingMore;
  final bool hasNext;
  final int page;
  final int pendingCount;
  final String? statusFilter;
  final Object? error;

  const OrdersState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasNext = false,
    this.page = 0,
    this.pendingCount = 0,
    this.statusFilter,
    this.error,
  });

  OrdersState copyWith({
    List<StoreOrder>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasNext,
    int? page,
    int? pendingCount,
    String? statusFilter,
    bool clearFilter = false,
    Object? error,
  }) {
    return OrdersState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      pendingCount: pendingCount ?? this.pendingCount,
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
      error: error,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final StoreService _service;
  final String? _academyId;
  static const int _limit = 20;

  OrdersNotifier(this._service, this._academyId) : super(const OrdersState()) {
    refresh();
  }

  Future<void> setFilter(String? status) async {
    state = state.copyWith(statusFilter: status, clearFilter: status == null);
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, items: [], page: 0);
    try {
      final res = await _service.getOrders(
        page: 1,
        limit: _limit,
        status: state.statusFilter,
        academyId: _academyId,
      );
      state = state.copyWith(
        items: res.items,
        loading: false,
        hasNext: res.hasNext,
        page: 1,
        pendingCount: res.pendingCount,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasNext || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final res = await _service.getOrders(
        page: state.page + 1,
        limit: _limit,
        status: state.statusFilter,
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

  Future<void> updateStatus(String id, String status) async {
    await _service.updateOrderStatus(id, status);
    await refresh();
  }

  Future<void> deleteOrder(String id) async {
    await _service.deleteOrder(id);
    await refresh();
  }
}

/// [academyId]: انظر توضيح storeProductsProvider أعلاه.
final storeOrdersProvider = StateNotifierProvider.autoDispose
    .family<OrdersNotifier, OrdersState, String?>((ref, academyId) {
  return OrdersNotifier(sl<StoreService>(), academyId);
});
