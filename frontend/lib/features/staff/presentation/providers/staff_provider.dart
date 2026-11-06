import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/staff/domain/entities/staff_attendance_entity.dart';
import 'package:hurghada_winners/features/staff/domain/entities/staff_entity.dart';
import 'package:hurghada_winners/features/staff/domain/repositories/staff_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaffState {
  final List<StaffEntity> staff;
  final int total;
  final String? search;

  /// أكاديمية super_admin التي يتصرف كها — نحتفظ بها ليعمل refresh بعد
  /// الإضافة/التعديل/الحذف. null لباقي الأدوار (الخادم يستنتجها من التوكن).
  final String? academyId;

  const StaffState({
    this.staff = const [],
    this.total = 0,
    this.search,
    this.academyId,
  });

  StaffState copyWith({
    List<StaffEntity>? staff,
    int? total,
    String? search,
    String? academyId,
  }) =>
      StaffState(
        staff: staff ?? this.staff,
        total: total ?? this.total,
        search: search ?? this.search,
        academyId: academyId ?? this.academyId,
      );
}

class StaffNotifier extends AsyncNotifier<StaffState> {
  StaffRepository get _repo => sl<StaffRepository>();

  @override
  Future<StaffState> build() async => const StaffState();

  Future<void> load({String? search, String? academyId}) async {
    // نتمسّك بالأكاديمية الأخيرة إن لم تُمرَّر (مثلاً في refresh بعد تعديل).
    final scope = academyId ?? state.valueOrNull?.academyId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result =
          await _repo.getStaff(search: search, limit: 200, academyId: scope);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (data) => StaffState(
          staff: data.staff,
          total: data.total,
          search: search,
          academyId: scope,
        ),
      );
    });
  }

  Future<void> refresh() => load(
        search: state.valueOrNull?.search,
        academyId: state.valueOrNull?.academyId,
      );

  Future<String?> createStaff({
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
  }) async {
    final result = await _repo.createStaff(
      fullName: fullName,
      position: position,
      phone: phone,
      email: email,
      hireDate: hireDate,
      sessionRate: sessionRate,
      workingDays: workingDays,
      photoPath: photoPath,
      academyId: academyId ?? state.valueOrNull?.academyId,
    );
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> updateStaff({
    required String id,
    String? fullName,
    String? position,
    String? phone,
    String? email,
    DateTime? hireDate,
    double? sessionRate,
    List<String>? workingDays,
    String? photoPath,
  }) async {
    final result = await _repo.updateStaff(
      id: id,
      fullName: fullName,
      position: position,
      phone: phone,
      email: email,
      hireDate: hireDate,
      sessionRate: sessionRate,
      workingDays: workingDays,
      photoPath: photoPath,
    );
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> deleteStaff(String id) async {
    final result = await _repo.deleteStaff(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }
}

final staffProvider =
    AsyncNotifierProvider<StaffNotifier, StaffState>(StaffNotifier.new);

// ---------------------------------------------------------------------------
// Staff Attendance
// ---------------------------------------------------------------------------

class StaffAttendanceNotifier
    extends AsyncNotifier<List<StaffAttendanceEntity>> {
  StaffRepository get _repo => sl<StaffRepository>();

  @override
  Future<List<StaffAttendanceEntity>> build() async => const [];

  Future<void> loadHistory({
    String? staffId,
    String? startDate,
    String? endDate,
    String? academyId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getAttendanceHistory(
        staffId: staffId,
        startDate: startDate,
        endDate: endDate,
        academyId: academyId,
      );
      return result.fold(
          (failure) => throw Exception(failure.message), (data) => data);
    });
  }

  Future<String?> markAttendance({
    required String staffId,
    required String date,
    required String status,
    String? notes,
  }) async {
    final result = await _repo.markAttendance(
        staffId: staffId, date: date, status: status, notes: notes);
    return result.fold((failure) => failure.message, (_) => null);
  }
}

final staffAttendanceProvider =
    AsyncNotifierProvider<StaffAttendanceNotifier, List<StaffAttendanceEntity>>(
        StaffAttendanceNotifier.new);

class StaffAttendanceReportNotifier
    extends AsyncNotifier<List<StaffAttendanceReportRow>> {
  StaffRepository get _repo => sl<StaffRepository>();

  @override
  Future<List<StaffAttendanceReportRow>> build() async => const [];

  Future<void> loadReport({
    required String startDate,
    required String endDate,
    String? academyId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getAttendanceReport(
        startDate: startDate,
        endDate: endDate,
        academyId: academyId,
      );
      return result.fold(
          (failure) => throw Exception(failure.message), (data) => data);
    });
  }
}

final staffAttendanceReportProvider = AsyncNotifierProvider<
    StaffAttendanceReportNotifier,
    List<StaffAttendanceReportRow>>(StaffAttendanceReportNotifier.new);
