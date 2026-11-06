import 'package:equatable/equatable.dart';

class PayrollEntity extends Equatable {
  final String id;
  final String academyId;
  final String staffId;
  final String staffName;
  final String staffPosition;
  final String month; // 'YYYY-MM'
  final double baseSalary;
  final double sessionRate; // المرتب = سعر التمرينة × أيام الحضور
  final int presentCount;
  final int absentCount;
  final String deductionType;
  final double deductionValue;
  final double deductionAmount;
  final double netSalary;
  final String status; // 'pending' | 'paid'
  final DateTime? paidAt;

  const PayrollEntity({
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
    this.paidAt,
  });

  @override
  List<Object?> get props => [
        id, academyId, staffId, staffName, staffPosition, month, baseSalary,
        sessionRate, presentCount, absentCount, deductionType,
        deductionValue, deductionAmount, netSalary, status, paidAt,
      ];
}

class PayrollReportRow extends Equatable {
  final String staffId;
  final String fullName;
  final String position;
  final double baseSalary;
  final double deductionAmount;
  final double netSalary;
  final String status;

  const PayrollReportRow({
    required this.staffId,
    required this.fullName,
    required this.position,
    required this.baseSalary,
    required this.deductionAmount,
    required this.netSalary,
    required this.status,
  });

  @override
  List<Object?> get props => [staffId, fullName, position, baseSalary, deductionAmount, netSalary, status];
}
