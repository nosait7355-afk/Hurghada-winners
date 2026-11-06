import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:dartz/dartz.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, List<SubscriptionEntity>>> getSubscriptionsByPlayer({
    required String playerId,
    String? status,
  });

  Future<
      Either<
          Failure,
          ({
            List<SubscriptionEntity> subscriptions,
            int total,
            int page,
            int totalPages,
          })>> getSubscriptionsByAcademy({
    required String academyId,
    String? type,
    String? status,
    String? playerId,
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, SubscriptionEntity>> getSubscriptionById(String id);

  Future<Either<Failure, SubscriptionEntity>> createSubscription({
    required String playerId,
    required String type,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? academyId,
  });

  Future<Either<Failure, SubscriptionEntity>> updateNotes({
    required String id,
    required String notes,
  });

  Future<Either<Failure, void>> deleteSubscription(String id);

  Future<Either<Failure, Map<String, dynamic>>> getRevenueSummary(
      String academyId);
}
