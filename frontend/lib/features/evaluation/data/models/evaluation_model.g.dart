// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvaluationModel _$EvaluationModelFromJson(Map<String, dynamic> json) =>
    EvaluationModel(
      id: json['_id'] as String,
      academyId: json['academyId'] as String,
      playerId: json['playerId'] as String,
      evaluatorRaw: json['evaluatorId'],
      evaluationDate: DateTime.parse(json['evaluationDate'] as String),
      fitness: (json['fitness'] as num).toDouble(),
      basicSkills: (json['basicSkills'] as num).toDouble(),
      attack: (json['attack'] as num).toDouble(),
      defense: (json['defense'] as num).toDouble(),
      commitment: (json['commitment'] as num).toDouble(),
      average: (json['average'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EvaluationModelToJson(EvaluationModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'academyId': instance.academyId,
      'playerId': instance.playerId,
      'evaluatorId': instance.evaluatorRaw,
      'evaluationDate': instance.evaluationDate.toIso8601String(),
      'fitness': instance.fitness,
      'basicSkills': instance.basicSkills,
      'attack': instance.attack,
      'defense': instance.defense,
      'commitment': instance.commitment,
      'average': instance.average,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
