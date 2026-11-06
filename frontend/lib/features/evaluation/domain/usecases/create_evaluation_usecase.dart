import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class CreateEvaluationParams {
  final String playerId;
  final double fitness;
  final double basicSkills;
  final double attack;
  final double defense;
  final double commitment;
  final String? notes;
  final String? academyId;
  final DateTime? evaluationDate;

  const CreateEvaluationParams({
    required this.playerId,
    required this.fitness,
    required this.basicSkills,
    required this.attack,
    required this.defense,
    required this.commitment,
    this.notes,
    this.academyId,
    this.evaluationDate,
  });
}

class CreateEvaluationUsecase
    extends UseCase<EvaluationEntity, CreateEvaluationParams> {
  final EvaluationRepository _repository;

  CreateEvaluationUsecase(this._repository);

  @override
  Future<Either<Failure, EvaluationEntity>> call(
      CreateEvaluationParams params) {
    return _repository.createEvaluation(
      playerId: params.playerId,
      fitness: params.fitness,
      basicSkills: params.basicSkills,
      attack: params.attack,
      defense: params.defense,
      commitment: params.commitment,
      notes: params.notes,
      academyId: params.academyId,
      evaluationDate: params.evaluationDate,
    );
  }
}
