import 'dart:convert';

import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/core/utils/multipart/image_multipart_helper.dart';
import 'package:hurghada_winners/features/player/data/created_account_buffer.dart';
import 'package:hurghada_winners/features/player/data/models/player_model.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

abstract class PlayerRemoteDatasource {
  Future<
      ({
        List<PlayerModel> players,
        int total,
        int page,
        int totalPages,
      })> getPlayers({
    String? academyId,
    String? search,
    int? birthYear,
    String? sport,
    String? attendanceDay,
    bool? hasAccount,
    String? groupId,
    int page = 1,
    int limit = 20,
  });

  Future<List<PlayerModel>> searchPlayers(String query);

  /// يرجّع لاعبي الأكاديمية اللي شهر ميلادهم = [month] (1-12)، مرتّبين حسب
  /// يوم الميلاد تصاعدياً. [academyId] مطلوب فقط لدور super_admin.
  Future<List<PlayerModel>> getPlayersBirthdays({
    required int month,
    String? academyId,
  });

  Future<PlayerModel> getPlayerById(String id);

  Future<PlayerModel> createPlayer({
    required String fullName,
    required DateTime birthDate,
    required String parentName,
    required String parentRelationship,
    String? parentJob,
    required String parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String> attendanceDays,
    String? academyId,
    required String imagePath,
    required String receiptPath,
    String? groupId,
  });

  Future<PlayerModel> updatePlayer({
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
  });

  Future<void> deletePlayer(String id);

  Future<void> deletePlayerImage(String id);
}

class PlayerRemoteDatasourceImpl implements PlayerRemoteDatasource {
  final ApiClient _apiClient;

  PlayerRemoteDatasourceImpl(this._apiClient);

  @override
  Future<
      ({
        List<PlayerModel> players,
        int total,
        int page,
        int totalPages,
      })> getPlayers({
    String? academyId,
    String? search,
    int? birthYear,
    String? sport,
    String? attendanceDay,
    bool? hasAccount,
    String? groupId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (academyId != null) 'academyId': academyId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (birthYear != null) 'birthYear': birthYear,
      if (sport != null && sport.isNotEmpty) 'sport': sport,
      if (attendanceDay != null && attendanceDay.isNotEmpty)
        'attendanceDay': attendanceDay,
      if (hasAccount != null) 'hasAccount': hasAccount.toString(),
      if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
    };

    final response = await _apiClient.get('/players', queryParameters: queryParams);
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;

    return (
      players: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<List<PlayerModel>> searchPlayers(String query) async {
    final response = await _apiClient.get(
      '/players/search',
      queryParameters: {'q': query},
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<List<PlayerModel>> getPlayersBirthdays({
    required int month,
    String? academyId,
  }) async {
    final response = await _apiClient.get(
      '/players/birthdays',
      queryParameters: {
        'month': month,
        if (academyId != null) 'academyId': academyId,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<PlayerModel> getPlayerById(String id) async {
    final response = await _apiClient.get('/players/$id');
    final body = response.data as Map<String, dynamic>;
    return PlayerModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<PlayerModel> createPlayer({
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
    // صورة اللاعب وإيصال الدفع إجباريان عند التسجيل أول مرة (الخادم يفرضهما).
    final formData = FormData.fromMap({
      'fullName': fullName,
      'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
      'parentName': parentName,
      'parentRelationship': parentRelationship,
      if (parentJob != null) 'parentJob': parentJob,
      'parentPhone': parentPhone,
      if (playerPhone != null) 'playerPhone': playerPhone,
      if (notes != null) 'notes': notes,
      if (sport != null && sport.isNotEmpty) 'sport': sport,
      'attendanceDays': jsonEncode(attendanceDays),
      if (academyId != null) 'academyId': academyId,
      if (groupId != null) 'groupId': groupId,
      'image': await buildImageMultipart(imagePath, filename: 'player_image.jpg'),
      'receipt': await buildImageMultipart(receiptPath, filename: 'receipt.jpg'),
    });
    final response = await _apiClient.postMultipart<Map<String, dynamic>>(
      '/players',
      data: formData,
    );
    final body = response.data as Map<String, dynamic>;
    CreatedAccountBuffer.set(body['account'] as Map<String, dynamic>?);
    return PlayerModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<PlayerModel> updatePlayer({
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
    if (imagePath != null) {
      final formMap = <String, dynamic>{
        if (fullName != null) 'fullName': fullName,
        if (birthDate != null) 'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
        if (parentName != null) 'parentName': parentName,
        if (parentRelationship != null) 'parentRelationship': parentRelationship,
        if (parentJob != null) 'parentJob': parentJob,
        if (parentPhone != null) 'parentPhone': parentPhone,
        if (playerPhone != null) 'playerPhone': playerPhone,
        if (notes != null) 'notes': notes,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
        if (attendanceDays != null) 'attendanceDays': jsonEncode(attendanceDays),
        if (groupId != null) 'groupId': groupId,
        'image': await buildImageMultipart(imagePath, filename: 'player_image.jpg'),
      };
      final formData = FormData.fromMap(formMap);
      final response = await _apiClient.putMultipart<Map<String, dynamic>>(
        '/players/$id',
        data: formData,
      );
      final body = response.data as Map<String, dynamic>;
      return PlayerModel.fromJson(body['data'] as Map<String, dynamic>);
    } else {
      final data = <String, dynamic>{
        if (fullName != null) 'fullName': fullName,
        if (birthDate != null) 'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
        if (parentName != null) 'parentName': parentName,
        if (parentRelationship != null) 'parentRelationship': parentRelationship,
        if (parentJob != null) 'parentJob': parentJob,
        if (parentPhone != null) 'parentPhone': parentPhone,
        if (playerPhone != null) 'playerPhone': playerPhone,
        if (notes != null) 'notes': notes,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
        if (attendanceDays != null) 'attendanceDays': attendanceDays,
        if (groupId != null) 'groupId': groupId,
      };
      final response = await _apiClient.put('/players/$id', data: data);
      final body = response.data as Map<String, dynamic>;
      return PlayerModel.fromJson(body['data'] as Map<String, dynamic>);
    }
  }

  @override
  Future<void> deletePlayer(String id) async {
    await _apiClient.delete('/players/$id');
  }

  @override
  Future<void> deletePlayerImage(String id) async {
    await _apiClient.delete('/players/$id/image');
  }
}
