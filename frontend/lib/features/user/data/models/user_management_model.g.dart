// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_management_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserManagementModel _$UserManagementModelFromJson(Map<String, dynamic> json) =>
    UserManagementModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      academyId: UserManagementModel._academyIdFromJson(json['academyId']),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserManagementModelToJson(
        UserManagementModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'academyId': instance.academyId,
      'isActive': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
