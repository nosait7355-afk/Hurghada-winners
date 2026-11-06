import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/payroll/data/models/payroll_model.dart';

/// [academyId] في التواقيع أدناه: أكاديمية super_admin التي يتصرف كها.
/// يتجاهلها الخادم لباقي الأدوار (مُقيَّدة بأكاديمية التوكن)، فنمرّرها دائماً.
abstract class PayrollRemoteDatasource {
  Future<List<PayrollModel>> generatePayroll({required String month, String? staffId, bool force = false, String? academyId});
  Future<List<PayrollModel>> getPayrollList({String? month, String? staffId, String? status, String? academyId});
  Future<({List<PayrollReportRowModel> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})> getPayrollReport(String month, {String? academyId});
  Future<PayrollModel> markPaid(String id);
}

class PayrollRemoteDatasourceImpl implements PayrollRemoteDatasource {
  final ApiClient _apiClient;
  PayrollRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<PayrollModel>> generatePayroll({required String month, String? staffId, bool force = false, String? academyId}) async {
    final response = await _apiClient.post('/payroll/generate', data: {
      'month': month,
      if (staffId != null) 'staffId': staffId,
      if (force) 'force': true,
      if (academyId != null) 'academyId': academyId,
    });
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as List<dynamic>).map((e) => PayrollModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PayrollModel>> getPayrollList({String? month, String? staffId, String? status, String? academyId}) async {
    final response = await _apiClient.get('/payroll', queryParameters: {
      if (month != null) 'month': month,
      if (staffId != null) 'staffId': staffId,
      if (status != null) 'status': status,
      if (academyId != null) 'academyId': academyId,
    });
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as List<dynamic>).map((e) => PayrollModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<({List<PayrollReportRowModel> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})> getPayrollReport(String month, {String? academyId}) async {
    final response = await _apiClient.get('/payroll/report', queryParameters: {
      'month': month,
      if (academyId != null) 'academyId': academyId,
    });
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final report = (data['report'] as List<dynamic>).map((e) => PayrollReportRowModel.fromJson(e as Map<String, dynamic>)).toList();
    final totals = data['totals'] as Map<String, dynamic>;
    return (
      report: report,
      totalBaseSalary: (totals['totalBaseSalary'] as num).toDouble(),
      totalDeductions: (totals['totalDeductions'] as num).toDouble(),
      totalNetSalary: (totals['totalNetSalary'] as num).toDouble(),
    );
  }

  @override
  Future<PayrollModel> markPaid(String id) async {
    final response = await _apiClient.patch('/payroll/$id/mark-paid');
    final body = response.data as Map<String, dynamic>;
    return PayrollModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}
