/// سجل تذكير مُرسَل للاعب — تاريخ ووقت الإرسال فقط (السيرفر يضيفه بعد فتح واتساب).
class ReminderLogEntry {
  final String playerId;
  final DateTime sentAt;
  const ReminderLogEntry({required this.playerId, required this.sentAt});

  factory ReminderLogEntry.fromJson(Map<String, dynamic> json) {
    return ReminderLogEntry(
      playerId: json['playerId'] as String? ?? '',
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// مباراة — نموذج بيانات مطابق لاستجابة /api/v1/matches. الحقول المحسوبة
/// (عدد اللاعبين/عدد التذكيرات/آخر تذكير) تُشتق محلياً من playerIds/reminderLog.
class MatchModel {
  final String id;
  final String academyId;
  final String? sport;
  final String name;
  final String location;
  final String date; // "YYYY-MM-DD"
  final String time; // "HH:mm"
  final String? notes;
  final List<String> playerIds;
  final List<ReminderLogEntry> reminderLog;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MatchModel({
    required this.id,
    required this.academyId,
    this.sport,
    required this.name,
    required this.location,
    required this.date,
    required this.time,
    this.notes,
    this.playerIds = const [],
    this.reminderLog = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get playersCount => playerIds.length;
  int get reminderCount => reminderLog.length;

  DateTime? get lastReminderAt {
    if (reminderLog.isEmpty) return null;
    return reminderLog
        .map((e) => e.sentAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['_id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      sport: json['sport'] as String?,
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      notes: json['notes'] as String?,
      playerIds: (json['playerIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      reminderLog: (json['reminderLog'] as List<dynamic>? ?? [])
          .map((e) => ReminderLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'academyId': academyId,
      'sport': sport,
      'name': name,
      'location': location,
      'date': date,
      'time': time,
      'notes': notes,
      'playerIds': playerIds,
    };
  }
}

/// لاعب ضمن تفاصيل المباراة — يُستخدم لعرض قائمة اللاعبين المضافين.
class MatchPlayer {
  final String id;
  final String fullName;
  final String playerCode;
  final String? imageUrl;
  final String parentPhone;
  final String? parentName;

  const MatchPlayer({
    required this.id,
    required this.fullName,
    required this.playerCode,
    this.imageUrl,
    required this.parentPhone,
    this.parentName,
  });

  factory MatchPlayer.fromJson(Map<String, dynamic> json) {
    return MatchPlayer(
      id: json['_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      playerCode: json['playerCode'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      parentPhone: json['parentPhone'] as String? ?? '',
      parentName: json['parentName'] as String?,
    );
  }
}

/// نتيجة GET /matches/:id — المباراة + لاعبوها.
class MatchDetail {
  final MatchModel match;
  final List<MatchPlayer> players;
  const MatchDetail({required this.match, required this.players});

  factory MatchDetail.fromJson(Map<String, dynamic> json) {
    return MatchDetail(
      match: MatchModel.fromJson(json['match'] as Map<String, dynamic>),
      players: (json['players'] as List<dynamic>? ?? [])
          .map((e) => MatchPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
