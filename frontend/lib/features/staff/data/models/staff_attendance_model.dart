import 'package:hurghada_winners/features/staff/domain/entities/staff_attendance_entity.dart';

class StaffAttendanceModel {
  final String id;
  final String staffId;
  final String academyId;
  final String date;
  final String status;
  final String? notes;
  final String? checkIn;
  final String? checkOut;

  const StaffAttendanceModel({
    required this.id,
    required this.staffId,
    required this.academyId,
    required this.date,
    required this.status,
    this.notes,
    this.checkIn,
    this.checkOut,
  });

  factory StaffAttendanceModel.fromJson(Map<String, dynamic> json) {
    final rawStaffId = json['staffId'];
    final staffId = rawStaffId is Map
        ? (rawStaffId['_id'] as String)
        : rawStaffId as String;
    return StaffAttendanceModel(
      id: json['_id'] as String,
      staffId: staffId,
      academyId: json['academyId'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
    );
  }

  StaffAttendanceEntity toEntity() => StaffAttendanceEntity(
        id: id,
        staffId: staffId,
        academyId: academyId,
        date: date,
        status: status,
        notes: notes,
        checkIn: checkIn,
        checkOut: checkOut,
      );
}

class StaffAttendanceReportRowModel {
  final String staffId;
  final String fullName;
  final String position;
  final int presentCount;
  final int absentCount;

  const StaffAttendanceReportRowModel({
    required this.staffId,
    required this.fullName,
    required this.position,
    required this.presentCount,
    required this.absentCount,
  });

  factory StaffAttendanceReportRowModel.fromJson(Map<String, dynamic> json) =>
      StaffAttendanceReportRowModel(
        staffId: json['staffId'] as String,
        fullName: json['fullName'] as String,
        position: json['position'] as String,
        presentCount: (json['presentCount'] as num).toInt(),
        absentCount: (json['absentCount'] as num).toInt(),
      );

  StaffAttendanceReportRow toEntity() => StaffAttendanceReportRow(
        staffId: staffId,
        fullName: fullName,
        position: position,
        presentCount: presentCount,
        absentCount: absentCount,
      );
}
