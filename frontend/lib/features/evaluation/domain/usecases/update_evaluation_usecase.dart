import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateEvaluationParams {
  final String id;
  final double? fitness;
  final double? basicSkills;
  final double? attack;
  final double? defense;
  final double? commitment;
  final String? notes;
  final DateTime? evaluationDate;

  const UpdateEvaluationParams({
    required this.id,
    this.fitness,
    this.basicSkills,
    this.attack,
    this.defense,
    this.commitment,
    this.notes,
    this.evaluationDate,
  });
}

class UpdateEvaluationUsecase
    extends UseCase<EvaluationEntity, UpdateEvaluationParams> {
  final EvaluationRepository _repository;

  UpdateEvaluationUsecase(this._repository);

  @override
  Future<Either<Failure, EvaluationEntity>> call(
      UpdateEvaluationParams params) {
    return _repository.updateEvaluation(
      id: params.id,
      fitness: params.fitness,
      basicSkills: params.basicSkills,
      attack: params.attack,
      defense: params.defense,
      commitment: params.commitment,
      notes: params.notes,
      evaluationDate: params.evaluationDate,
    );
  }
}
