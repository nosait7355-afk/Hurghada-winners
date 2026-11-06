import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حالة قائمة فيديوهات مرقّمة (Pagination + Lazy Loading) — نفس نمط الألبوم.
@immutable
class VideosState {
  final List<PlayerVideo> items;
  final bool loading;
  final bool loadingMore;
  final bool hasNext;
  final int page;
  final Object? error;

  const VideosState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasNext = false,
    this.page = 0,
    this.error,
  });

  VideosState copyWith({
    List<PlayerVideo>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasNext,
    int? page,
  }) {
    return VideosState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      error: null,
    );
  }
}

class VideosNotifier extends StateNotifier<VideosState> {
  final PlayerVideoService _service;

  /// مطلوب لجهة الإدارة فقط — جهة اللاعب تستنتجه الخادم من التوكن.
  final String? playerId;
  static const int _limit = 20;

  VideosNotifier(this._service, {this.playerId}) : super(const VideosState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const VideosState(loading: true);
    try {
      final res = await _service.getVideos(playerId: playerId, page: 1, limit: _limit);
      state = VideosState(
        items: res.items,
        loading: false,
        hasNext: res.hasNext,
        page: 1,
      );
    } catch (e) {
      state = VideosState(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasNext || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final res = await _service.getVideos(
        playerId: playerId,
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

  /// يستبدل عنصراً واحداً في مكانه (بعد إعجاب أو تعليق) بدل إعادة تحميل
  /// الصفحة كاملة — يحافظ على موضع التمرير.
  void replace(PlayerVideo video) {
    state = state.copyWith(
      items: [
        for (final v in state.items) if (v.id == video.id) video else v,
      ],
    );
  }

  /// تعديل عدّاد التعليقات محلياً بعد إضافة/حذف تعليق من الشيت.
  void bumpComments(String videoId, int delta) {
    state = state.copyWith(
      items: [
        for (final v in state.items)
          if (v.id == videoId)
            v.copyWith(commentsCount: (v.commentsCount + delta).clamp(0, 1 << 30))
          else
            v,
      ],
    );
  }
}

/// خدمة جهة الإدارة (مسارات /player-videos).
final adminVideoServiceProvider = Provider<PlayerVideoService>(
  (ref) => PlayerVideoService(sl<ApiClient>(), playerSide: false),
);

/// خدمة جهة اللاعب (مسارات /player/videos).
final playerVideoServiceProvider = Provider<PlayerVideoService>(
  (ref) => PlayerVideoService(sl<ApiClient>(), playerSide: true),
);

/// فيديوهات لاعب معيّن — جهة الإدارة.
final academyPlayerVideosProvider = StateNotifierProvider.autoDispose
    .family<VideosNotifier, VideosState, String>((ref, playerId) {
  return VideosNotifier(ref.watch(adminVideoServiceProvider), playerId: playerId);
});

/// فيديوهات اللاعب الحالي — جهة اللاعب.
final myVideosProvider =
    StateNotifierProvider.autoDispose<VideosNotifier, VideosState>((ref) {
  return VideosNotifier(ref.watch(playerVideoServiceProvider));
});
