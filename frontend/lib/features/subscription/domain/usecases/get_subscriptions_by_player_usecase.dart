import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class GetSubscriptionsByPlayerParams {
  final String playerId;
  final String? status;

  const GetSubscriptionsByPlayerParams({
    required this.playerId,
    this.status,
  });
}

class GetSubscriptionsByPlayerUsecase
    extends UseCase<List<SubscriptionEntity>, GetSubscriptionsByPlayerParams> {
  final SubscriptionRepository _repository;

  GetSubscriptionsByPlayerUsecase(this._repository);

  @override
  Future<Either<Failure, List<SubscriptionEntity>>> call(
      GetSubscriptionsByPlayerParams params) {
    return _repository.getSubscriptionsByPlayer(
      playerId: params.playerId,
      status: params.status,
    );
  }
}
