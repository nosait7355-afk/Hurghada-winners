import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'evaluation_model.g.dart';

@JsonSerializable()
class EvaluationModel {
  @JsonKey(name: '_id')
  final String id;
  final String academyId;
  final String playerId;
  @JsonKey(name: 'evaluatorId')
  final dynamic evaluatorRaw;
  final DateTime evaluationDate;
  final double fitness;
  final double basicSkills;
  final double attack;
  final double defense;
  final double commitment;
  final double average;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const EvaluationModel({
    required this.id,
    required this.academyId,
    required this.playerId,
    required this.evaluatorRaw,
    required this.evaluationDate,
    required this.fitness,
    required this.basicSkills,
    required this.attack,
    required this.defense,
    required this.commitment,
    required this.average,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  String get evaluatorId => evaluatorRaw is Map
      ? (evaluatorRaw as Map)['_id'] as String
      : evaluatorRaw as String;

  String? get evaluatorName => evaluatorRaw is Map
      ? (evaluatorRaw as Map)['name'] as String?
      : null;

  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluationModelToJson(this);

  EvaluationEntity toEntity() => EvaluationEntity(
        id: id,
        academyId: academyId,
        playerId: playerId,
        evaluatorId: evaluatorId,
        evaluatorName: evaluatorName,
        evaluationDate: evaluationDate,
        fitness: fitness,
        basicSkills: basicSkills,
        attack: attack,
        defense: defense,
        commitment: commitment,
        average: average,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
