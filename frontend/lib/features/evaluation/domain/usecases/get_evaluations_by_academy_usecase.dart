import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class GetEvaluationsByAcademyParams {
  final String academyId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  const GetEvaluationsByAcademyParams({
    required this.academyId,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 100,
  });
}

class GetEvaluationsByAcademyUsecase extends UseCase<
    ({
      List<EvaluationEntity> evaluations,
      int total,
      int page,
      int totalPages,
    }),
    GetEvaluationsByAcademyParams> {
  final EvaluationRepository _repository;

  GetEvaluationsByAcademyUsecase(this._repository);

  @override
  Future<
      Either<
          Failure,
          ({
            List<EvaluationEntity> evaluations,
            int total,
            int page,
            int totalPages,
          })>> call(GetEvaluationsByAcademyParams params) {
    return _repository.getEvaluationsByAcademy(
      academyId: params.academyId,
      startDate: params.startDate,
      endDate: params.endDate,
      page: params.page,
      limit: params.limit,
    );
  }
}
