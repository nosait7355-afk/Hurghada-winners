import 'package:equatable/equatable.dart';

class StaffEntity extends Equatable {
  final String id;
  final String academyId;
  final String fullName;
  final String position;
  final String phone;
  final String? email;
  final String? photoUrl;
  final DateTime hireDate;
  // المرتب = سعر التمرينة × أيام الحضور. null للحسابات الإدارية المحدودة
  // (الخادم يحذف الحقول المالية من الاستجابة) — "محجوب" لا "صفر".
  final double? sessionRate;
  final List<String> workingDays;
  final bool isActive;
  final DateTime createdAt;

  const StaffEntity({
    required this.id,
    required this.academyId,
    required this.fullName,
    required this.position,
    required this.phone,
    this.email,
    this.photoUrl,
    required this.hireDate,
    this.sessionRate,
    this.workingDays = const [],
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        academyId,
        fullName,
        position,
        phone,
        email,
        photoUrl,
        hireDate,
        sessionRate,
        workingDays,
        isActive,
        createdAt,
      ];
}
