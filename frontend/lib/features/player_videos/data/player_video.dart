/// فيديو في بروفايل اللاعب — رابط خارجي (يوتيوب/درايف) تضيفه الإدارة.
class PlayerVideo {
  final String id;
  final String academyId;
  final String playerId;
  final String title;
  final String description;
  final String url;
  final String provider; // youtube | drive | image
  /// معرّف فيديو يوتيوب (فارغ لغير يوتيوب) — يستخدمه المشغّل الداخلي.
  final String videoKey;
  final String thumbnailUrl;
  final String createdByName;
  final int likesCount;
  final bool likedByMe;
  final int commentsCount;
  final DateTime? createdAt;

  const PlayerVideo({
    required this.id,
    required this.academyId,
    required this.playerId,
    required this.title,
    required this.description,
    required this.url,
    required this.provider,
    required this.videoKey,
    required this.thumbnailUrl,
    required this.createdByName,
    required this.likesCount,
    required this.likedByMe,
    required this.commentsCount,
    this.createdAt,
  });

  bool get isYoutube => provider == 'youtube';

  /// صورة مرفوعة (url = رابط الصورة) تُعرض بجانب الفيديوهات.
  bool get isImage => provider == 'image';

  factory PlayerVideo.fromJson(Map<String, dynamic> json) {
    return PlayerVideo(
      id: json['_id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      playerId: json['playerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      provider: json['provider'] as String? ?? 'youtube',
      videoKey: json['videoKey'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      createdByName: json['createdByName'] as String? ?? '',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  /// نسخة محلية بعد إعجاب/تعليق — يتفادى إعادة تحميل القائمة كاملة.
  PlayerVideo copyWith({
    int? likesCount,
    bool? likedByMe,
    int? commentsCount,
  }) {
    return PlayerVideo(
      id: id,
      academyId: academyId,
      playerId: playerId,
      title: title,
      description: description,
      url: url,
      provider: provider,
      videoKey: videoKey,
      thumbnailUrl: thumbnailUrl,
      createdByName: createdByName,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt,
    );
  }
}

/// تعليق على فيديو. authorType: 'player' أو 'academy'.
class VideoComment {
  final String id;
  final String videoId;
  final String authorType;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  const VideoComment({
    required this.id,
    required this.videoId,
    required this.authorType,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  bool get isFromAcademy => authorType == 'academy';

  factory VideoComment.fromJson(Map<String, dynamic> json) {
    return VideoComment(
      id: json['_id'] as String? ?? '',
      videoId: json['videoId'] as String? ?? '',
      authorType: json['authorType'] as String? ?? 'player',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
