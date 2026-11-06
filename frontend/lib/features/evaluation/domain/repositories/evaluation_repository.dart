import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:dartz/dartz.dart';

abstract class EvaluationRepository {
  Future<
      Either<
          Failure,
          ({
            List<EvaluationEntity> evaluations,
            int total,
            int page,
            int totalPages,
          })>> getEvaluationsByPlayer({
    required String playerId,
    int page = 1,
    int limit = 10,
  });

  Future<Either<Failure, EvaluationEntity?>> getLatestEvaluation(
      String playerId);

  Future<Either<Failure, EvaluationEntity>> getEvaluationById(String id);

  Future<Either<Failure, EvaluationEntity>> createEvaluation({
    required String playerId,
    required double fitness,
    required double basicSkills,
    required double attack,
    required double defense,
    required double commitment,
    String? notes,
    String? academyId,
    DateTime? evaluationDate,
  });

  Future<Either<Failure, EvaluationEntity>> updateEvaluation({
    required String id,
    double? fitness,
    double? basicSkills,
    double? attack,
    double? defense,
    double? commitment,
    String? notes,
    DateTime? evaluationDate,
  });

  Future<Either<Failure, void>> deleteEvaluation(String id);

  Future<
      Either<
          Failure,
          ({
            List<EvaluationEntity> evaluations,
            int total,
            int page,
            int totalPages,
          })>> getEvaluationsByAcademy({
    required String academyId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 100,
  });
}
