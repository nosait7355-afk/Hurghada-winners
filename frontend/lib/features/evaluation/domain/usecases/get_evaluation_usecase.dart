import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class GetEvaluationParams {
  final String id;

  const GetEvaluationParams({required this.id});
}

class GetEvaluationUsecase
    extends UseCase<EvaluationEntity, GetEvaluationParams> {
  final EvaluationRepository _repository;

  GetEvaluationUsecase(this._repository);

  @override
  Future<Either<Failure, EvaluationEntity>> call(GetEvaluationParams params) {
    return _repository.getEvaluationById(params.id);
  }
}
