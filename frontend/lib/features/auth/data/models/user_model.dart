import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String email;
  final String role;
  @JsonKey(name: 'academy_id')
  final String? academyId;
  @JsonKey(name: 'academy_name')
  final String? academyName;
  @JsonKey(name: 'isActive', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'canViewReports', defaultValue: true)
  final bool canViewReports;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      role: role == 'super_admin'
          ? UserRole.superAdmin
          : role == 'admin'
              ? UserRole.admin
              : UserRole.academyAdmin,
      academyId: academyId,
      academyName: academyName,
      isActive: isActive,
      canViewReports: canViewReports,
      createdAt: createdAt,
    );
  }
}
