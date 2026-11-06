import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteEvaluationParams {
  final String id;

  const DeleteEvaluationParams({required this.id});
}

class DeleteEvaluationUsecase extends UseCase<void, DeleteEvaluationParams> {
  final EvaluationRepository _repository;

  DeleteEvaluationUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteEvaluationParams params) {
    return _repository.deleteEvaluation(params.id);
  }
}
