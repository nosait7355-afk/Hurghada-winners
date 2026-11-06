import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:hurghada_winners/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetSubscriptionsByTypeParams {
  final String? academyId;
  const GetSubscriptionsByTypeParams({this.academyId});
}

class GetSubscriptionsByTypeUsecase extends UseCase<SubscriptionsByTypeEntity, GetSubscriptionsByTypeParams> {
  final DashboardRepository _repository;

  GetSubscriptionsByTypeUsecase(this._repository);

  @override
  Future<Either<Failure, SubscriptionsByTypeEntity>> call(GetSubscriptionsByTypeParams params) {
    return _repository.getSubscriptionsByType(academyId: params.academyId);
  }
}
