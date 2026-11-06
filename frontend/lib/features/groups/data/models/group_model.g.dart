// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupModel _$GroupModelFromJson(Map<String, dynamic> json) => GroupModel(
      id: json['_id'] as String,
      academyId: json['academyId'] as String,
      sportId: json['sportId'] as String?,
      name: json['name'] as String,
      ageGroup: json['ageGroup'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      playersCount: (json['playersCount'] as num?)?.toInt() ?? 0,
      occupationRate: (json['occupationRate'] as num?)?.toInt(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$GroupModelToJson(GroupModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'academyId': instance.academyId,
      'sportId': instance.sportId,
      'name': instance.name,
      'ageGroup': instance.ageGroup,
      'capacity': instance.capacity,
      'isActive': instance.isActive,
      'playersCount': instance.playersCount,
      'occupationRate': instance.occupationRate,
      'order': instance.order,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
