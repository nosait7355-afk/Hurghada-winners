import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:hurghada_winners/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetEvaluationDistributionParams {
  final String? academyId;
  const GetEvaluationDistributionParams({this.academyId});
}

class GetEvaluationDistributionUsecase extends UseCase<EvaluationDistributionEntity, GetEvaluationDistributionParams> {
  final DashboardRepository _repository;

  GetEvaluationDistributionUsecase(this._repository);

  @override
  Future<Either<Failure, EvaluationDistributionEntity>> call(GetEvaluationDistributionParams params) {
    return _repository.getEvaluationDistribution(academyId: params.academyId);
  }
}
