import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class GetSubscriptionParams {
  final String id;

  const GetSubscriptionParams({required this.id});
}

class GetSubscriptionUsecase
    extends UseCase<SubscriptionEntity, GetSubscriptionParams> {
  final SubscriptionRepository _repository;

  GetSubscriptionUsecase(this._repository);

  @override
  Future<Either<Failure, SubscriptionEntity>> call(
      GetSubscriptionParams params) {
    return _repository.getSubscriptionById(params.id);
  }
}
