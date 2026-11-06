// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      academyId: json['academy_id'] as String?,
      academyName: json['academy_name'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      canViewReports: json['canViewReports'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'academy_id': instance.academyId,
      'academy_name': instance.academyName,
      'isActive': instance.isActive,
      'canViewReports': instance.canViewReports,
      'created_at': instance.createdAt.toIso8601String(),
    };
