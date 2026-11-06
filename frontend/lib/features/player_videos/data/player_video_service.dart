import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/core/utils/multipart/image_multipart_helper.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';
import 'package:dio/dio.dart';

/// صفحة فيديوهات (عناصر + هل توجد صفحة تالية) لدعم Pagination/Lazy Loading.
class VideoPage {
  final List<PlayerVideo> items;
  final bool hasNext;
  const VideoPage(this.items, this.hasNext);
}

/// خدمة فيديوهات بروفايل اللاعب — تعيد استخدام ApiClient نفسه.
///
/// جهتان بنفس البيانات ومسارين مختلفين:
///  • الإدارة: /player-videos       (إضافة/تعديل/حذف + إعجاب + تعليق)
///  • اللاعب:  /player/videos       (قراءة + إعجاب + تعليق على فيديوهاته)
///
/// [playerSide] يحدّد أي مجموعة مسارات تُستخدم، فتشترك الشاشتان في نفس
/// الويدجتات دون تكرار منطق الشبكة.
class PlayerVideoService {
  final ApiClient _api;
  final bool playerSide;

  const PlayerVideoService(this._api, {this.playerSide = false});

  String get _base => playerSide ? '/player/videos' : '/player-videos';

  VideoPage _parse(Response<Map<String, dynamic>> res) {
    final body = res.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>? ?? [])
        .map((e) => PlayerVideo.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>?;
    return VideoPage(list, meta?['hasNext'] as bool? ?? false);
  }

  PlayerVideo _one(Response<Map<String, dynamic>> res) => PlayerVideo.fromJson(
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
      );

  // ── قراءة ──
  /// [playerId] مطلوب لجهة الإدارة فقط؛ جهة اللاعب تعيد فيديوهاته حصراً.
  Future<VideoPage> getVideos({
    String? playerId,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (!playerSide && playerId != null) 'playerId': playerId,
      },
    );
    return _parse(res);
  }

  // ── إدارة (جهة المدير فقط) ──
  Future<PlayerVideo> create({
    required String playerId,
    required String title,
    required String url,
    String? description,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/player-videos',
      data: {
        'playerId': playerId,
        'title': title,
        'url': url,
        if (description != null) 'description': description,
      },
    );
    return _one(res);
  }

  /// رفع صورة لبروفايل اللاعب (جهة الإدارة).
  Future<PlayerVideo> createImage({
    required String playerId,
    required String imagePath,
    String? title,
    String? description,
  }) async {
    final form = FormData.fromMap({
      'playerId': playerId,
      if (title != null && title.isNotEmpty) 'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'image': await buildImageMultipart(imagePath, filename: 'photo.jpg'),
    });
    final res = await _api.postMultipart<Map<String, dynamic>>(
      '/player-videos/image',
      data: form,
    );
    return _one(res);
  }

  Future<PlayerVideo> update({
    required String id,
    String? title,
    String? description,
    String? url,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/player-videos/$id',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (url != null) 'url': url,
      },
    );
    return _one(res);
  }

  Future<void> delete(String id) async => _api.delete('/player-videos/$id');

  // ── إعجاب (الجهتان) ──
  Future<PlayerVideo> setLike(String id, bool liked) async {
    final path = '$_base/$id/like';
    final res = liked
        ? await _api.post<Map<String, dynamic>>(path)
        : await _api.delete<Map<String, dynamic>>(path);
    return _one(res);
  }

  // ── تعليقات (الجهتان) ──
  Future<List<VideoComment>> getComments(String id, {int limit = 100}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '$_base/$id/comments',
      queryParameters: {'page': 1, 'limit': limit},
    );
    final body = res.data as Map<String, dynamic>;
    return (body['data'] as List<dynamic>? ?? [])
        .map((e) => VideoComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VideoComment> addComment(String id, String text) async {
    final res = await _api.post<Map<String, dynamic>>(
      '$_base/$id/comments',
      data: {'text': text},
    );
    return VideoComment.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteComment(String videoId, String commentId) async =>
      _api.delete('$_base/$videoId/comments/$commentId');
}
