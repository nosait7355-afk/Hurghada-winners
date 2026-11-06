import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:hurghada_winners/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:hurghada_winners/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDatasource _remoteDatasource;

  DashboardRepositoryImpl({required DashboardRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  Future<Either<Failure, T>> _execute<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, DashboardStatsEntity>> getStats({String? academyId}) {
    return _execute(() async {
      final model = await _remoteDatasource.getStats(academyId: academyId);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<RevenueByMonthEntity>>> getRevenueByMonth({String? academyId}) {
    return _execute(() async {
      final models = await _remoteDatasource.getRevenueByMonth(academyId: academyId);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, SubscriptionsByTypeEntity>> getSubscriptionsByType({String? academyId}) {
    return _execute(() async {
      final model = await _remoteDatasource.getSubscriptionsByType(academyId: academyId);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<PlayersByBirthYearEntity>>> getPlayersByBirthYear({String? academyId}) {
    return _execute(() async {
      final models = await _remoteDatasource.getPlayersByBirthYear(academyId: academyId);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, EvaluationDistributionEntity>> getEvaluationDistribution({String? academyId}) {
    return _execute(() async {
      final model = await _remoteDatasource.getEvaluationDistribution(academyId: academyId);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, RecentActivitiesEntity>> getRecentActivities({String? academyId}) {
    return _execute(() async {
      final model = await _remoteDatasource.getRecentActivities(academyId: academyId);
      return model.toEntity();
    });
  }
}
