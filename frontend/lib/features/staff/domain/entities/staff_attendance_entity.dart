import 'package:equatable/equatable.dart';

class StaffAttendanceEntity extends Equatable {
  final String id;
  final String staffId;
  final String academyId;
  final String date; // 'YYYY-MM-DD'
  final String status; // 'present' | 'absent'
  final String? notes;
  final String? checkIn; // 'HH:mm'
  final String? checkOut; // 'HH:mm'

  const StaffAttendanceEntity({
    required this.id,
    required this.staffId,
    required this.academyId,
    required this.date,
    required this.status,
    this.notes,
    this.checkIn,
    this.checkOut,
  });

  /// مدة التواجد بالدقائق (null إن لم يُسجَّل حضور وانصراف معاً).
  int? get minutesWorked {
    if (checkIn == null || checkOut == null) return null;
    int m(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    final d = m(checkOut!) - m(checkIn!);
    return d >= 0 ? d : null;
  }

  @override
  List<Object?> get props =>
      [id, staffId, academyId, date, status, notes, checkIn, checkOut];
}

class StaffAttendanceReportRow extends Equatable {
  final String staffId;
  final String fullName;
  final String position;
  final int presentCount;
  final int absentCount;

  const StaffAttendanceReportRow({
    required this.staffId,
    required this.fullName,
    required this.position,
    required this.presentCount,
    required this.absentCount,
  });

  @override
  List<Object?> get props =>
      [staffId, fullName, position, presentCount, absentCount];
}
