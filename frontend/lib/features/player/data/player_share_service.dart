import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';

/// حالة مشاركة بروفايل لاعب (جهة الإدارة).
class PlayerShareInfo {
  final String? token;
  final String bio;
  const PlayerShareInfo({required this.token, required this.bio});

  bool get isEnabled => token != null && token!.isNotEmpty;

  /// hash routing في نسخة الويب — لا يحتاج أي إعداد إضافي في nginx.
  String? get link =>
      isEnabled ? '${AppConstants.publicWebBaseUrl}/#/p/$token' : null;

  factory PlayerShareInfo.fromJson(Map<String, dynamic> j) => PlayerShareInfo(
        token: j['token'] as String?,
        bio: j['bio'] as String? ?? '',
      );
}

/// البروفايل العام كما يراه أي شخص معه الرابط (بدون بيانات حساسة).
class PublicPlayerProfile {
  final String fullName;
  final String? imageUrl;
  final String bio;
  final int? birthYear;
  final String? sport;
  final String academyName;
  final String? academyLogoUrl;
  final List<PlayerVideo> videos;

  const PublicPlayerProfile({
    required this.fullName,
    required this.imageUrl,
    required this.bio,
    required this.birthYear,
    required this.sport,
    required this.academyName,
    required this.academyLogoUrl,
    required this.videos,
  });

  factory PublicPlayerProfile.fromJson(Map<String, dynamic> j) =>
      PublicPlayerProfile(
        fullName: j['fullName'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
        bio: j['bio'] as String? ?? '',
        birthYear: (j['birthYear'] as num?)?.toInt(),
        sport: j['sport'] as String?,
        academyName: j['academyName'] as String? ?? '',
        academyLogoUrl: j['academyLogoUrl'] as String?,
        videos: ((j['videos'] as List<dynamic>?) ?? const [])
            .map((e) => PlayerVideo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PlayerShareService {
  final ApiClient _api;
  PlayerShareService(this._api);

  PlayerShareInfo _info(dynamic res) => PlayerShareInfo.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);

  Future<PlayerShareInfo> getInfo(String playerId) async =>
      _info(await _api.get<Map<String, dynamic>>('/players/$playerId/share'));

  /// ينشئ الرابط إن لم يوجد، أو يصدر رمزاً جديداً مع [regenerate].
  Future<PlayerShareInfo> enable(String playerId, {bool regenerate = false}) async =>
      _info(await _api.post<Map<String, dynamic>>(
        '/players/$playerId/share',
        data: {'regenerate': regenerate},
      ));

  Future<PlayerShareInfo> disable(String playerId) async =>
      _info(await _api.delete<Map<String, dynamic>>('/players/$playerId/share'));

  Future<PlayerShareInfo> updateBio(String playerId, String bio) async =>
      _info(await _api.patch<Map<String, dynamic>>(
        '/players/$playerId/bio',
        data: {'bio': bio},
      ));

  Future<PublicPlayerProfile> getPublicProfile(String token) async {
    final res = await _api.get<Map<String, dynamic>>('/public/players/$token');
    return PublicPlayerProfile.fromJson(
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }
}
