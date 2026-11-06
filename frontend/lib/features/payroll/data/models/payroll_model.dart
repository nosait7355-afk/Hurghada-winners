import 'package:hurghada_winners/features/payroll/domain/entities/payroll_entity.dart';

class PayrollModel {
  final String id;
  final String academyId;
  final String staffId;
  final String staffName;
  final String staffPosition;
  final String month;
  final double baseSalary;
  final double sessionRate; // المرتب = سعر التمرينة × أيام الحضور
  final int presentCount;
  final int absentCount;
  final String deductionType;
  final double deductionValue;
  final double deductionAmount;
  final double netSalary;
  final String status;
  final String? paidAtStr;

  const PayrollModel({
    required this.id,
    required this.academyId,
    required this.staffId,
    required this.staffName,
    required this.staffPosition,
    required this.month,
    required this.baseSalary,
    required this.sessionRate,
    required this.presentCount,
    required this.absentCount,
    required this.deductionType,
    required this.deductionValue,
    required this.deductionAmount,
    required this.netSalary,
    required this.status,
    this.paidAtStr,
  });

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    final rawStaffId = json['staffId'];
    final isPopulated = rawStaffId is Map;
    final staffId = isPopulated ? (rawStaffId['_id'] as String) : rawStaffId as String;
    final staffName = isPopulated ? (rawStaffId['fullName'] as String? ?? '') : '';
    final staffPosition = isPopulated ? (rawStaffId['position'] as String? ?? '') : '';

    return PayrollModel(
      id: json['_id'] as String,
      academyId: json['academyId'] as String,
      staffId: staffId,
      staffName: staffName,
      staffPosition: staffPosition,
      month: json['month'] as String,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      sessionRate: (json['sessionRate'] as num?)?.toDouble() ?? 0,
      presentCount: (json['presentCount'] as num).toInt(),
      absentCount: (json['absentCount'] as num).toInt(),
      deductionType: json['deductionType'] as String? ?? 'fixed',
      deductionValue: (json['deductionValue'] as num?)?.toDouble() ?? 0,
      deductionAmount: (json['deductionAmount'] as num).toDouble(),
      netSalary: (json['netSalary'] as num).toDouble(),
      status: json['status'] as String,
      paidAtStr: json['paidAt'] as String?,
    );
  }

  PayrollEntity toEntity() => PayrollEntity(
        id: id,
        academyId: academyId,
        staffId: staffId,
        staffName: staffName,
        staffPosition: staffPosition,
        month: month,
        baseSalary: baseSalary,
        sessionRate: sessionRate,
        presentCount: presentCount,
        absentCount: absentCount,
        deductionType: deductionType,
        deductionValue: deductionValue,
        deductionAmount: deductionAmount,
        netSalary: netSalary,
        status: status,
        paidAt: paidAtStr != null ? DateTime.parse(paidAtStr!) : null,
      );
}

class PayrollReportRowModel {
  final String staffId;
  final String fullName;
  final String position;
  final double baseSalary;
  final double deductionAmount;
  final double netSalary;
  final String status;

  const PayrollReportRowModel({
    required this.staffId,
    required this.fullName,
    required this.position,
    required this.baseSalary,
    required this.deductionAmount,
    required this.netSalary,
    required this.status,
  });

  factory PayrollReportRowModel.fromJson(Map<String, dynamic> json) => PayrollReportRowModel(
        staffId: json['staffId'] as String,
        fullName: json['fullName'] as String? ?? '',
        position: json['position'] as String? ?? '',
        baseSalary: (json['baseSalary'] as num).toDouble(),
        deductionAmount: (json['deductionAmount'] as num).toDouble(),
        netSalary: (json['netSalary'] as num).toDouble(),
        status: json['status'] as String,
      );

  PayrollReportRow toEntity() => PayrollReportRow(
        staffId: staffId,
        fullName: fullName,
        position: position,
        baseSalary: baseSalary,
        deductionAmount: deductionAmount,
        netSalary: netSalary,
        status: status,
      );
}
