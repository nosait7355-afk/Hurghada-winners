import 'package:equatable/equatable.dart';

enum UserRole { superAdmin, academyAdmin, admin }

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? academyId;
  final String? academyName;
  final bool isActive;

  /// صلاحية الاطّلاع على لوحة الإحصائيات والإيرادات والتقارير.
  final bool canViewReports;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.academyId,
    this.academyName,
    this.isActive = true,
    this.canViewReports = true,
    required this.createdAt,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAcademyAdmin => role == UserRole.academyAdmin;
  bool get isAdmin => role == UserRole.admin;

  /// يملك صلاحيات اللاعبين والاشتراكات فقط
  bool get isLimitedAdmin => role == UserRole.admin;

  /// يملك صلاحيات كاملة على أكاديميته
  bool get isAcademyLevel => role == UserRole.academyAdmin || role == UserRole.admin;

  String get fullName => name;

  @override
  List<Object?> get props =>
      [id, name, email, role, academyId, academyName, isActive, canViewReports, createdAt];
}
