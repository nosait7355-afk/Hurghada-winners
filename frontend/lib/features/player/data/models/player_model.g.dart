// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerModel _$PlayerModelFromJson(Map<String, dynamic> json) => PlayerModel(
      id: json['_id'] as String,
      academyId: json['academyId'] as String,
      playerCode: json['playerCode'] as String,
      fullName: json['fullName'] as String,
      birthDateStr: json['birthDate'] as String,
      imageUrl: json['image_url'] as String?,
      parentName: json['parentName'] as String,
      parentRelationship: json['parentRelationship'] as String,
      parentJob: json['parentJob'] as String?,
      parentPhone: json['parentPhone'] as String,
      playerPhone: json['playerPhone'] as String?,
      notes: json['notes'] as String?,
      sport: json['sport'] as String?,
      attendanceDays: (json['attendanceDays'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      groupId: json['groupId'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PlayerModelToJson(PlayerModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'academyId': instance.academyId,
      'playerCode': instance.playerCode,
      'fullName': instance.fullName,
      'birthDate': instance.birthDateStr,
      'image_url': instance.imageUrl,
      'parentName': instance.parentName,
      'parentRelationship': instance.parentRelationship,
      'parentJob': instance.parentJob,
      'parentPhone': instance.parentPhone,
      'playerPhone': instance.playerPhone,
      'notes': instance.notes,
      'sport': instance.sport,
      'attendanceDays': instance.attendanceDays,
      'groupId': instance.groupId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
