import 'package:hurghada_winners/features/attendance/domain/entities/attendance_report_entity.dart';

/// تحويل استجابة GET /attendance/report إلى AttendanceReport.
class AttendanceReportMapper {
  static AttendanceReport fromJson(Map<String, dynamic> json) {
    final rawRows = (json['rows'] as List<dynamic>?) ?? const [];
    return AttendanceReport(
      startDate: (json['startDate'] ?? '').toString(),
      endDate: (json['endDate'] ?? '').toString(),
      sport: json['sport'] as String?,
      subscription: (json['subscription'] as String?) ?? 'all',
      playersCount: (json['playersCount'] as num?)?.toInt() ?? 0,
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      totalPresent: (json['totalPresent'] as num?)?.toInt() ?? 0,
      totalAbsent: (json['totalAbsent'] as num?)?.toInt() ?? 0,
      rows: rawRows
          .map((e) => _rowFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  static AttendanceReportRow _rowFromJson(Map<String, dynamic> json) {
    return AttendanceReportRow(
      playerId: (json['playerId'] ?? '').toString(),
      playerCode: (json['playerCode'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      sport: json['sport'] as String?,
      // خادم قديم بلا الحقل: كل الصفوف كانت للاعبين نشطين.
      subscriptionStatus: (json['subscriptionStatus'] as String?) ?? 'active',
      subscriptionStart: _date(json['subscriptionStart']),
      subscriptionEnd: _date(json['subscriptionEnd']),
      expected: (json['expected'] as num?)?.toInt() ?? 0,
      expectedTotal: (json['expectedTotal'] as num?)?.toInt() ??
          (json['expected'] as num?)?.toInt() ??
          0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      rate: (json['rate'] as num?)?.toInt() ?? 0,
    );
  }
}
