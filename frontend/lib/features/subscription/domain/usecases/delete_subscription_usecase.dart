import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteSubscriptionParams {
  final String id;

  const DeleteSubscriptionParams({required this.id});
}

class DeleteSubscriptionUsecase
    extends UseCase<void, DeleteSubscriptionParams> {
  final SubscriptionRepository _repository;

  DeleteSubscriptionUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteSubscriptionParams params) {
    return _repository.deleteSubscription(params.id);
  }
}
