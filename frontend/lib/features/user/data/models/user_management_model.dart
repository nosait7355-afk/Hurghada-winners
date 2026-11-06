import 'package:hurghada_winners/features/user/domain/entities/user_management_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_management_model.g.dart';

@JsonSerializable()
class UserManagementModel {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String email;
  final String role;
  // academyId may be a plain String (ObjectId) or a populated object {"_id":..., "name":...}
  @JsonKey(name: 'academyId', fromJson: _academyIdFromJson)
  final String academyId;

  static String _academyIdFromJson(dynamic value) {
    if (value is String) return value;
    if (value is Map) return (value['_id'] as String?) ?? '';
    return '';
  }
  @JsonKey(name: 'isActive', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const UserManagementModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.academyId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserManagementModel.fromJson(Map<String, dynamic> json) =>
      _$UserManagementModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserManagementModelToJson(this);

  UserManagementEntity toEntity() => UserManagementEntity(
        id: id,
        name: name,
        email: email,
        role: role,
        academyId: academyId,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
