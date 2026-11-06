import 'package:equatable/equatable.dart';

/// نوع الحضور — يحدد لأي اشتراك يُحتسب (القاعدة على الخادم).
enum AttendanceKind {
  /// حضور عادي داخل فترة اشتراك نشط.
  regular('regular'),

  /// اشتراك منتهٍ والدفع لاحقاً: يُحتسب من حصص التجديد القادم.
  payLater('pay_later'),

  /// تعويض غياب سابق: يُحتسب حضوراً للاشتراك السابق.
  makeup('makeup'),

  /// حصة مجانية: لا تُحتسب لأي اشتراك.
  free('free');

  final String apiValue;
  const AttendanceKind(this.apiValue);

  static AttendanceKind fromApi(String? v) => AttendanceKind.values.firstWhere(
        (k) => k.apiValue == v,
        orElse: () => AttendanceKind.regular,
      );
}

/// لاعب مختصر كما يرجعه الخادم في الحضور (المسح/البحث/الغائبين).
class AttendancePlayer extends Equatable {
  final String id;
  final String fullName;
  final String playerCode;
  final String? sport;
  final String? imageUrl;

  const AttendancePlayer({
    required this.id,
    required this.fullName,
    required this.playerCode,
    this.sport,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, fullName, playerCode, sport, imageUrl];
}

/// حضور/غياب لاعب في اشتراك (نشط: منذ بدايته حتى اليوم، منتهٍ: كامل فترته).
class AttendanceSubscriptionStats extends Equatable {
  /// active | expired | none
  final String status;
  final String? subscriptionId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int present;
  final int absent;

  /// أيام التدريب المتوقعة حتى اليوم.
  final int expected;

  /// أيام التدريب على كامل فترة الاشتراك.
  final int expectedTotal;

  /// الأيام المتبقية في الاشتراك النشط (null بلا اشتراك).
  final int? daysRemaining;

  const AttendanceSubscriptionStats({
    required this.status,
    this.subscriptionId,
    this.startDate,
    this.endDate,
    this.present = 0,
    this.absent = 0,
    this.expected = 0,
    this.expectedTotal = 0,
    this.daysRemaining,
  });

  static const none = AttendanceSubscriptionStats(status: 'none');

  bool get isActive => status == 'active';
  bool get isNone => status == 'none';

  /// نشط وباقٍ عليه 7 أيام أو أقل.
  bool get isExpiringSoon => isActive && (daysRemaining ?? 99) <= 7;

  @override
  List<Object?> get props => [
        status,
        subscriptionId,
        startDate,
        endDate,
        present,
        absent,
        expected,
        expectedTotal,
        daysRemaining,
      ];
}

/// ملخص حضور لاعب في اشتراكه الأخير — GET /attendance/player/:id/summary.
class AttendancePlayerSummary extends Equatable {
  final AttendancePlayer player;
  final AttendanceSubscriptionStats stats;

  const AttendancePlayerSummary({required this.player, required this.stats});

  @override
  List<Object?> get props => [player, stats];
}

/// نتيجة تسجيل الحضور القادمة من POST /attendance.
class AttendanceRecordResult extends Equatable {
  final bool recorded;
  final bool alreadyToday;

  /// الاشتراك منتهٍ ولم يُرسَل نوع حضور — الواجهة تعرض الخيارات ثم تعيد الإرسال.
  final bool subscriptionExpired;
  final AttendanceKind kind;
  final AttendancePlayer player;
  final AttendanceSubscriptionStats stats;
  final String message;

  const AttendanceRecordResult({
    required this.recorded,
    required this.alreadyToday,
    this.subscriptionExpired = false,
    this.kind = AttendanceKind.regular,
    required this.player,
    this.stats = AttendanceSubscriptionStats.none,
    required this.message,
  });

  @override
  List<Object?> get props =>
      [recorded, alreadyToday, subscriptionExpired, kind, player, stats, message];
}

/// سطر في سجل الحضور القادم من GET /attendance.
class AttendanceLogEntry extends Equatable {
  final String id;
  final String playerId;
  final String playerName;
  final String playerCode;
  final String? imageUrl;
  final String? sport;
  final String date; // 'YYYY-MM-DD'
  final String time; // 'HH:mm'
  final DateTime timestamp;
  final AttendanceKind kind;

  const AttendanceLogEntry({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.playerCode,
    this.imageUrl,
    this.sport,
    required this.date,
    required this.time,
    required this.timestamp,
    this.kind = AttendanceKind.regular,
  });

  @override
  List<Object?> get props => [
        id,
        playerId,
        playerName,
        playerCode,
        imageUrl,
        sport,
        date,
        time,
        timestamp,
        kind,
      ];
}

/// صفحة من سجل الحضور. [absentPlayers] لا يُملأ إلا مع يوم محدد (الصفحة الأولى).
typedef AttendanceLogResult = ({
  List<AttendanceLogEntry> records,
  int total,
  int page,
  int totalPages,
  List<AttendancePlayer> absentPlayers,
});
