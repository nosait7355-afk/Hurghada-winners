import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/academy_album/data/academy_album_service.dart';
import 'package:hurghada_winners/features/academy_album/data/album_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حالة ألبوم مرقّمة (Pagination + Lazy Loading): تحمّل صفحة صفحة وتُلحقها.
@immutable
class AlbumState {
  final List<AlbumImage> items;
  final bool loading; // تحميل الصفحة الأولى
  final bool loadingMore; // تحميل صفحة إضافية
  final bool hasNext;
  final int page;
  final Object? error;

  const AlbumState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasNext = false,
    this.page = 0,
    this.error,
  });

  AlbumState copyWith({
    List<AlbumImage>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasNext,
    int? page,
    Object? error,
    bool clearError = false,
  }) {
    return AlbumState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AlbumNotifier extends StateNotifier<AlbumState> {
  final AcademyAlbumService _service;
  final bool playerSide;

  /// أكاديمية super_admin التي يتصرف كها (null لباقي الأدوار — يعتمد الخادم
  /// على أكاديمية التوكن). غير مستخدم في جهة اللاعب.
  final String? academyId;
  static const int _limit = 20;

  AlbumNotifier(this._service, {required this.playerSide, this.academyId})
      : super(const AlbumState()) {
    refresh();
  }

  Future<AlbumPage> _fetch(int page) => playerSide
      ? _service.getPlayerAlbum(page: page, limit: _limit)
      : _service.getAlbum(page: page, limit: _limit, academyId: academyId);

  /// إعادة التحميل من الصفحة الأولى.
  Future<void> refresh() async {
    state = const AlbumState(loading: true);
    try {
      final res = await _fetch(1);
      state = AlbumState(
        items: res.items,
        loading: false,
        hasNext: res.hasNext,
        page: 1,
      );
    } catch (e) {
      state = AlbumState(loading: false, error: e);
    }
  }

  /// تحميل الصفحة التالية (يُستدعى عند الاقتراب من نهاية القائمة).
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasNext || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final res = await _fetch(state.page + 1);
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

/// ألبوم المدير (CRUD).
/// [academyId]: أكاديمية المدير الحالية، أو الأكاديمية التي يتصرف كها
/// super_admin (null لباقي الأدوار — الخادم يستنتجها من التوكن).
final academyAlbumProvider = StateNotifierProvider.autoDispose
    .family<AlbumNotifier, AlbumState, String?>((ref, academyId) {
  return AlbumNotifier(
    sl<AcademyAlbumService>(),
    playerSide: false,
    academyId: academyId,
  );
});

/// ألبوم اللاعب (قراءة فقط — أكاديميته حصراً).
final playerAlbumProvider =
    StateNotifierProvider.autoDispose<AlbumNotifier, AlbumState>((ref) {
  return AlbumNotifier(sl<AcademyAlbumService>(), playerSide: true);
});
