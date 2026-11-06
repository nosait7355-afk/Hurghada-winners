import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class CreateSubscriptionParams {
  final String playerId;
  final String type;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final String? academyId;

  const CreateSubscriptionParams({
    required this.playerId,
    required this.type,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.notes,
    this.academyId,
  });
}

class CreateSubscriptionUsecase
    extends UseCase<SubscriptionEntity, CreateSubscriptionParams> {
  final SubscriptionRepository _repository;

  CreateSubscriptionUsecase(this._repository);

  @override
  Future<Either<Failure, SubscriptionEntity>> call(
      CreateSubscriptionParams params) {
    return _repository.createSubscription(
      playerId: params.playerId,
      type: params.type,
      amount: params.amount,
      startDate: params.startDate,
      endDate: params.endDate,
      notes: params.notes,
      academyId: params.academyId,
    );
  }
}
