import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class GetLatestEvaluationParams {
  final String playerId;

  const GetLatestEvaluationParams({required this.playerId});
}

class GetLatestEvaluationUsecase
    extends UseCase<EvaluationEntity?, GetLatestEvaluationParams> {
  final EvaluationRepository _repository;

  GetLatestEvaluationUsecase(this._repository);

  @override
  Future<Either<Failure, EvaluationEntity?>> call(
      GetLatestEvaluationParams params) {
    return _repository.getLatestEvaluation(params.playerId);
  }
}
