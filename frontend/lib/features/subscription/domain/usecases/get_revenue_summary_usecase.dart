import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class GetRevenueSummaryParams {
  final String academyId;

  const GetRevenueSummaryParams({required this.academyId});
}

class GetRevenueSummaryUsecase
    extends UseCase<Map<String, dynamic>, GetRevenueSummaryParams> {
  final SubscriptionRepository _repository;

  GetRevenueSummaryUsecase(this._repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
      GetRevenueSummaryParams params) {
    return _repository.getRevenueSummary(params.academyId);
  }
}
