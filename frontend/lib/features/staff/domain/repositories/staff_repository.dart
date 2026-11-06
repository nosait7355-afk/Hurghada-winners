import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/staff/domain/entities/staff_attendance_entity.dart';
import 'package:hurghada_winners/features/staff/domain/entities/staff_entity.dart';
import 'package:dartz/dartz.dart';

abstract class StaffRepository {
  /// [academyId]: أكاديمية super_admin التي يتصرف كها (يتجاهلها الخادم لباقي الأدوار).
  Future<
          Either<Failure,
              ({List<StaffEntity> staff, int total, int page, int totalPages})>>
      getStaff({
    String? search,
    bool showInactive = false,
    int page = 1,
    int limit = 50,
    String? academyId,
  });

  Future<Either<Failure, StaffEntity>> getStaffById(String id);

  Future<Either<Failure, StaffEntity>> createStaff({
    required String fullName,
    required String position,
    required String phone,
    String? email,
    required DateTime hireDate,
    double? sessionRate,
    required List<String> workingDays,
    // اختياريان: الحساب الإداري المحدود لا يرسلهما، والخادم يثبّت قيماً محايدة.
    String? photoPath,
    String? academyId,
  });

  Future<Either<Failure, StaffEntity>> updateStaff({
    required String id,
    String? fullName,
    String? position,
    String? phone,
    String? email,
    DateTime? hireDate,
    double? sessionRate,
    List<String>? workingDays,
    String? photoPath,
  });

  Future<Either<Failure, void>> deleteStaff(String id);

  Future<Either<Failure, StaffAttendanceEntity>> markAttendance({
    required String staffId,
    required String date,
    required String status,
    String? notes,
  });

  Future<Either<Failure, List<StaffAttendanceEntity>>> getAttendanceHistory({
    String? staffId,
    String? startDate,
    String? endDate,
    String? academyId,
  });

  Future<Either<Failure, List<StaffAttendanceReportRow>>> getAttendanceReport({
    required String startDate,
    required String endDate,
    String? academyId,
  });
}
