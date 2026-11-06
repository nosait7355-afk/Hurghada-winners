import 'package:equatable/equatable.dart';

class EvaluationEntity extends Equatable {
  final String id;
  final String academyId;
  final String playerId;
  final String evaluatorId;
  final String? evaluatorName;
  final DateTime evaluationDate;
  final double fitness;
  final double basicSkills;
  final double attack;
  final double defense;
  final double commitment;
  final double average;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EvaluationEntity({
    required this.id,
    required this.academyId,
    required this.playerId,
    required this.evaluatorId,
    this.evaluatorName,
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

  String get gradeLabel {
    if (average >= 8) return 'ممتاز';
    if (average >= 6) return 'جيد';
    return 'يحتاج تحسين';
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        playerId,
        evaluatorId,
        evaluatorName,
        evaluationDate,
        fitness,
        basicSkills,
        attack,
        defense,
        commitment,
        average,
        notes,
        createdAt,
        updatedAt,
      ];
}
