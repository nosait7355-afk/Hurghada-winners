import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class GetEvaluationsByPlayerParams {
  final String playerId;
  final int page;
  final int limit;

  const GetEvaluationsByPlayerParams({
    required this.playerId,
    this.page = 1,
    this.limit = 10,
  });
}

class GetEvaluationsByPlayerUsecase extends UseCase<
    ({
      List<EvaluationEntity> evaluations,
      int total,
      int page,
      int totalPages,
    }),
    GetEvaluationsByPlayerParams> {
  final EvaluationRepository _repository;

  GetEvaluationsByPlayerUsecase(this._repository);

  @override
  Future<
      Either<
          Failure,
          ({
            List<EvaluationEntity> evaluations,
            int total,
            int page,
            int totalPages,
          })>> call(GetEvaluationsByPlayerParams params) {
    return _repository.getEvaluationsByPlayer(
      playerId: params.playerId,
      page: params.page,
      limit: params.limit,
    );
  }
}
