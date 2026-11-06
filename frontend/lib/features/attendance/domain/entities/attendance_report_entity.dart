import 'package:equatable/equatable.dart';

/// سطر تقرير الحضور/الغياب للاعب واحد — على أساس اشتراكه النشط.
class AttendanceReportRow extends Equatable {
  final String playerId;
  final String playerCode;
  final String fullName;
  final String? sport;

  /// active | expired — المنتهي يظهر بلا أرقام.
  final String subscriptionStatus;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;

  final int expected; // أيام التدريب المتوقعة من بداية الاشتراك حتى اليوم
  final int expectedTotal; // أيام التدريب على كامل فترة الاشتراك (للدوائر)
  final int present;
  final int absent; // = max(المتوقع − الحضور، 0)
  final int rate; // نسبة الالتزام %

  const AttendanceReportRow({
    required this.playerId,
    required this.playerCode,
    required this.fullName,
    this.sport,
    required this.subscriptionStatus,
    this.subscriptionStart,
    this.subscriptionEnd,
    required this.expected,
    required this.expectedTotal,
    required this.present,
    required this.absent,
    required this.rate,
  });

  bool get isActive => subscriptionStatus == 'active';

  @override
  List<Object?> get props => [
        playerId,
        playerCode,
        fullName,
        sport,
        subscriptionStatus,
        subscriptionStart,
        subscriptionEnd,
        expected,
        expectedTotal,
        present,
        absent,
        rate,
      ];
}

/// تقرير الحضور/الغياب الكامل القادم من GET /attendance/report.
class AttendanceReport extends Equatable {
  final String startDate;
  final String endDate;
  final String? sport;

  /// active (نشطون فقط) | all
  final String subscription;
  final int playersCount;
  final int activeCount;
  final int totalPresent;
  final int totalAbsent;
  final List<AttendanceReportRow> rows;

  const AttendanceReport({
    required this.startDate,
    required this.endDate,
    this.sport,
    required this.subscription,
    required this.playersCount,
    required this.activeCount,
    required this.totalPresent,
    required this.totalAbsent,
    required this.rows,
  });

  /// نسبة الالتزام الإجمالية = الحضور ÷ (الحضور + الغياب).
  int get overallRate {
    final total = totalPresent + totalAbsent;
    return total > 0 ? (totalPresent / total * 100).round() : 0;
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        sport,
        subscription,
        playersCount,
        activeCount,
        totalPresent,
        totalAbsent,
        rows,
      ];
}
