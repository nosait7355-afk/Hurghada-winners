import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:dartz/dartz.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardStatsEntity>> getStats({String? academyId});
  Future<Either<Failure, List<RevenueByMonthEntity>>> getRevenueByMonth({String? academyId});
  Future<Either<Failure, SubscriptionsByTypeEntity>> getSubscriptionsByType({String? academyId});
  Future<Either<Failure, List<PlayersByBirthYearEntity>>> getPlayersByBirthYear({String? academyId});
  Future<Either<Failure, EvaluationDistributionEntity>> getEvaluationDistribution({String? academyId});
  Future<Either<Failure, RecentActivitiesEntity>> getRecentActivities({String? academyId});
}
