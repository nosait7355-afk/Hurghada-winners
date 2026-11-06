import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// تحويل لاعب مختصر ({id, fullName, playerCode, sport, image_url}).
class AttendancePlayerMapper {
  static AttendancePlayer fromJson(Map<String, dynamic> j) => AttendancePlayer(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        fullName: (j['fullName'] ?? '').toString(),
        playerCode: (j['playerCode'] ?? '').toString(),
        sport: j['sport'] as String?,
        imageUrl: j['image_url'] as String?,
      );
}

/// تحويل إحصائيات الاشتراك (stats) القادمة مع المسح والملخص.
class AttendanceStatsMapper {
  static AttendanceSubscriptionStats fromJson(Map<String, dynamic>? j) {
    if (j == null) return AttendanceSubscriptionStats.none;
    final sub = j['subscription'] as Map<String, dynamic>?;
    return AttendanceSubscriptionStats(
      status: (j['status'] as String?) ?? 'none',
      subscriptionId: sub?['id']?.toString(),
      startDate: _date(sub?['startDate']),
      endDate: _date(sub?['endDate']),
      present: (j['present'] as num?)?.toInt() ?? 0,
      absent: (j['absent'] as num?)?.toInt() ?? 0,
      expected: (j['expected'] as num?)?.toInt() ?? 0,
      expectedTotal: (j['expectedTotal'] as num?)?.toInt() ?? 0,
      daysRemaining: (j['daysRemaining'] as num?)?.toInt(),
    );
  }
}

/// تحويل سجل حضور (مع playerId مُعبَّأ) إلى AttendanceLogEntry.
class AttendanceLogMapper {
  static AttendanceLogEntry fromJson(Map<String, dynamic> json) {
    final rawPlayer = json['playerId'];
    String playerId = '';
    String playerName = '';
    String playerCode = '';
    String? imageUrl;
    if (rawPlayer is Map) {
      playerId = (rawPlayer['_id'] ?? rawPlayer['id'] ?? '').toString();
      playerName = (rawPlayer['fullName'] ?? '').toString();
      playerCode = (rawPlayer['playerCode'] ?? '').toString();
      imageUrl = rawPlayer['image_url'] as String?;
    } else if (rawPlayer != null) {
      playerId = rawPlayer.toString();
    }

    // السجلات القديمة بلا kind: pay_later لو سُجِّلت على اشتراك منتهٍ، وإلا regular.
    final rawKind = json['kind'] as String?;
    final kind = rawKind != null
        ? AttendanceKind.fromApi(rawKind)
        : (json['subscriptionExpiredAtCheckin'] == true
            ? AttendanceKind.payLater
            : AttendanceKind.regular);

    return AttendanceLogEntry(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      playerId: playerId,
      playerName: playerName,
      playerCode: playerCode,
      imageUrl: imageUrl,
      sport: json['sport'] as String?,
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
      kind: kind,
    );
  }
}

/// تحويل استجابة POST /attendance إلى AttendanceRecordResult.
class AttendanceRecordMapper {
  static AttendanceRecordResult fromResponse(
    Map<String, dynamic> data,
    String message,
  ) {
    return AttendanceRecordResult(
      recorded: data['recorded'] == true,
      alreadyToday: data['alreadyToday'] == true,
      subscriptionExpired: data['subscriptionExpired'] == true,
      kind: AttendanceKind.fromApi(data['kind'] as String?),
      player: AttendancePlayerMapper.fromJson(
          (data['player'] as Map<String, dynamic>?) ?? const {}),
      stats: AttendanceStatsMapper.fromJson(
          data['stats'] as Map<String, dynamic>?),
      message: message,
    );
  }
}
