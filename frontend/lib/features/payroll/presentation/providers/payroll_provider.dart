import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/payroll/domain/entities/payroll_entity.dart';
import 'package:hurghada_winners/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayrollState {
  final List<PayrollEntity> records;
  final String? month;

  /// أكاديمية super_admin التي يتصرف كها — نحتفظ بها ليعمل refresh بعد
  /// التوليد/تأكيد الدفع. null لباقي الأدوار (الخادم يستنتجها من التوكن).
  final String? academyId;

  const PayrollState({this.records = const [], this.month, this.academyId});
}

class PayrollNotifier extends AsyncNotifier<PayrollState> {
  PayrollRepository get _repo => sl<PayrollRepository>();

  @override
  Future<PayrollState> build() async => const PayrollState();

  Future<void> load(String month, {String? academyId}) async {
    // نتمسّك بالأكاديمية الأخيرة إن لم تُمرَّر (مثلاً في refresh بعد تأكيد الدفع).
    final scope = academyId ?? state.valueOrNull?.academyId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getPayrollList(month: month, academyId: scope);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (data) => PayrollState(records: data, month: month, academyId: scope),
      );
    });
  }

  Future<void> refresh() async {
    final s = state.valueOrNull;
    if (s?.month != null) await load(s!.month!, academyId: s.academyId);
  }

  Future<String?> generate(String month, {String? academyId}) async {
    final scope = academyId ?? state.valueOrNull?.academyId;
    final result = await _repo.generatePayroll(month: month, academyId: scope);
    return result.fold((failure) => failure.message, (_) {
      load(month, academyId: scope);
      return null;
    });
  }

  Future<String?> markPaid(String id) async {
    final result = await _repo.markPaid(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }
}

final payrollProvider = AsyncNotifierProvider<PayrollNotifier, PayrollState>(PayrollNotifier.new);

class PayrollReportNotifier extends AsyncNotifier<({List<PayrollReportRow> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})> {
  PayrollRepository get _repo => sl<PayrollRepository>();

  @override
  Future<({List<PayrollReportRow> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})> build() async =>
      (report: const <PayrollReportRow>[], totalBaseSalary: 0.0, totalDeductions: 0.0, totalNetSalary: 0.0);

  Future<void> load(String month, {String? academyId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getPayrollReport(month, academyId: academyId);
      return result.fold((failure) => throw Exception(failure.message), (data) => data);
    });
  }
}

final payrollReportProvider = AsyncNotifierProvider<PayrollReportNotifier,
    ({List<PayrollReportRow> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})>(PayrollReportNotifier.new);
