import 'package:hurghada_winners/features/staff/domain/entities/staff_entity.dart';

class StaffModel {
  final String id;
  final String academyId;
  final String fullName;
  final String position;
  final String phone;
  final String? email;
  final String? photoUrl;
  final String hireDateStr;
  // المرتب = سعر التمرينة × أيام الحضور. null للحسابات الإدارية المحدودة
  // (الخادم يحذف الحقول المالية من الاستجابة) — "محجوب" لا "صفر".
  final double? sessionRate;
  final List<String> workingDays;
  final bool isActive;
  final String createdAtStr;

  const StaffModel({
    required this.id,
    required this.academyId,
    required this.fullName,
    required this.position,
    required this.phone,
    this.email,
    this.photoUrl,
    required this.hireDateStr,
    this.sessionRate,
    this.workingDays = const [],
    this.isActive = true,
    required this.createdAtStr,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
        id: json['_id'] as String,
        academyId: json['academyId'] as String,
        fullName: json['fullName'] as String,
        position: json['position'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        photoUrl: json['photo_url'] as String?,
        hireDateStr: json['hireDate'] as String,
        sessionRate: (json['sessionRate'] as num?)?.toDouble(),
        workingDays: (json['workingDays'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
        createdAtStr: json['created_at'] as String,
      );

  StaffEntity toEntity() => StaffEntity(
        id: id,
        academyId: academyId,
        fullName: fullName,
        position: position,
        phone: phone,
        email: email,
        photoUrl: photoUrl,
        hireDate: DateTime.parse(hireDateStr),
        sessionRate: sessionRate,
        workingDays: workingDays,
        isActive: isActive,
        createdAt: DateTime.parse(createdAtStr),
      );
}
