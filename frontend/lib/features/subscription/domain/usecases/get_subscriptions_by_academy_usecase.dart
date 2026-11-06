import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class GetSubscriptionsByAcademyParams {
  final String academyId;
  final String? type;
  final String? status;
  final String? playerId;
  final int page;
  final int limit;

  const GetSubscriptionsByAcademyParams({
    required this.academyId,
    this.type,
    this.status,
    this.playerId,
    this.page = 1,
    this.limit = 20,
  });
}

class GetSubscriptionsByAcademyUsecase extends UseCase<
    ({
      List<SubscriptionEntity> subscriptions,
      int total,
      int page,
      int totalPages,
    }),
    GetSubscriptionsByAcademyParams> {
  final SubscriptionRepository _repository;

  GetSubscriptionsByAcademyUsecase(this._repository);

  @override
  Future<
      Either<
          Failure,
          ({
            List<SubscriptionEntity> subscriptions,
            int total,
            int page,
            int totalPages,
          })>> call(GetSubscriptionsByAcademyParams params) {
    return _repository.getSubscriptionsByAcademy(
      academyId: params.academyId,
      type: params.type,
      status: params.status,
      playerId: params.playerId,
      page: params.page,
      limit: params.limit,
    );
  }
}
