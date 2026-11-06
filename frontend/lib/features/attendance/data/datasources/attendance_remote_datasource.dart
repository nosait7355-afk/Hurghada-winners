import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/attendance/data/models/attendance_model.dart';
import 'package:hurghada_winners/features/attendance/data/models/attendance_report_model.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_report_entity.dart';

/// "اليوم" بتوقيت الجهاز — الخادم UTC، فنرسله ليُحسب الحضور على يوم الأكاديمية.
String _localToday() {
  final d = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

abstract class AttendanceRemoteDatasource {
  Future<AttendanceRecordResult> recordAttendance({
    String? code,
    String? playerId,
    required String localDate,
    required String localTime,
    AttendanceKind? mode,
  });

  Future<AttendanceLogResult> getAttendanceLog({
    String? academyId,
    String? date,
    String? startDate,
    String? endDate,
    String? sport,
    String? playerId,
    int page,
    int limit,
  });

  Future<AttendanceReport> getAttendanceReport({
    String? academyId,
    String? sport,
    String subscription,
  });

  Future<List<AttendancePlayer>> searchPlayers({
    String? academyId,
    required String query,
    String? sport,
  });

  Future<AttendancePlayerSummary> getPlayerSummary(String playerId);

  Future<void> deleteAttendance(String id);
}

class AttendanceRemoteDatasourceImpl implements AttendanceRemoteDatasource {
  final ApiClient _apiClient;

  AttendanceRemoteDatasourceImpl(this._apiClient);

  @override
  Future<AttendanceRecordResult> recordAttendance({
    String? code,
    String? playerId,
    required String localDate,
    required String localTime,
    AttendanceKind? mode,
  }) async {
    final data = <String, dynamic>{
      if (code != null) 'code': code,
      if (playerId != null) 'playerId': playerId,
      'localDate': localDate,
      'localTime': localTime,
      if (mode != null && mode != AttendanceKind.regular) 'mode': mode.apiValue,
    };
    final response = await _apiClient.post('/attendance', data: data);
    final body = response.data as Map<String, dynamic>;
    return AttendanceRecordMapper.fromResponse(
      (body['data'] as Map<String, dynamic>),
      (body['message'] as String?) ?? '',
    );
  }

  @override
  Future<AttendanceLogResult> getAttendanceLog({
    String? academyId,
    String? date,
    String? startDate,
    String? endDate,
    String? sport,
    String? playerId,
    int page = 1,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (academyId != null) 'academyId': academyId,
      if (date != null) 'date': date,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (sport != null && sport.isNotEmpty) 'sport': sport,
      if (playerId != null) 'playerId': playerId,
    };
    final response =
        await _apiClient.get('/attendance', queryParameters: query);
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => AttendanceLogMapper.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      records: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
      absentPlayers: ((meta['absentPlayers'] as List<dynamic>?) ?? const [])
          .map((e) => AttendancePlayerMapper.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<AttendanceReport> getAttendanceReport({
    String? academyId,
    String? sport,
    String subscription = 'active',
  }) async {
    final query = <String, dynamic>{
      if (academyId != null) 'academyId': academyId,
      if (sport != null && sport.isNotEmpty) 'sport': sport,
      'subscription': subscription,
      'localDate': _localToday(),
    };
    final response =
        await _apiClient.get('/attendance/report', queryParameters: query);
    final body = response.data as Map<String, dynamic>;
    return AttendanceReportMapper.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<AttendancePlayer>> searchPlayers({
    String? academyId,
    required String query,
    String? sport,
  }) async {
    final response = await _apiClient.get(
      '/attendance/players',
      queryParameters: {
        'search': query,
        if (academyId != null) 'academyId': academyId,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return ((body['data'] as List<dynamic>?) ?? const [])
        .map((e) => AttendancePlayerMapper.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AttendancePlayerSummary> getPlayerSummary(String playerId) async {
    final response = await _apiClient.get(
      '/attendance/player/$playerId/summary',
      queryParameters: {'localDate': _localToday()},
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return AttendancePlayerSummary(
      player: AttendancePlayerMapper.fromJson(
          data['player'] as Map<String, dynamic>),
      stats: AttendanceStatsMapper.fromJson(
          data['stats'] as Map<String, dynamic>?),
    );
  }

  @override
  Future<void> deleteAttendance(String id) async {
    await _apiClient.delete('/attendance/$id');
  }
}
