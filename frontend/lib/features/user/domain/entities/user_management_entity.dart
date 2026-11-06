import 'package:equatable/equatable.dart';

class UserManagementEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String academyId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserManagementEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.academyId,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAcademyAdmin => role == 'academy_admin';

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        academyId,
        isActive,
        createdAt,
        updatedAt,
      ];
}
