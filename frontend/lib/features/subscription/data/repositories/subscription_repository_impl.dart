import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDatasource _remoteDatasource;

  SubscriptionRepositoryImpl(
      {required SubscriptionRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<SubscriptionEntity>>> getSubscriptionsByPlayer({
    required String playerId,
    String? status,
  }) async {
    try {
      final models = await _remoteDatasource.getSubscriptionsByPlayer(
        playerId: playerId,
        status: status,
      );
      return Right(models.map((m) => m.toEntity()).toList());
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
  }) async {
    try {
      final result = await _remoteDatasource.getSubscriptionsByAcademy(
        academyId: academyId,
        type: type,
        status: status,
        playerId: playerId,
        page: page,
        limit: limit,
      );
      return Right((
        subscriptions: result.subscriptions.map((m) => m.toEntity()).toList(),
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      ));
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
  Future<Either<Failure, SubscriptionEntity>> getSubscriptionById(
      String id) async {
    try {
      final model = await _remoteDatasource.getSubscriptionById(id);
      return Right(model.toEntity());
    } on NotFoundException {
      return const Left(NotFoundFailure());
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> createSubscription({
    required String playerId,
    required String type,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? academyId,
  }) async {
    try {
      final model = await _remoteDatasource.createSubscription(
        playerId: playerId,
        type: type,
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        academyId: academyId,
      );
      return Right(model.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
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
  Future<Either<Failure, SubscriptionEntity>> updateNotes({
    required String id,
    required String notes,
  }) async {
    try {
      final model = await _remoteDatasource.updateNotes(id: id, notes: notes);
      return Right(model.toEntity());
    } on NotFoundException {
      return const Left(NotFoundFailure());
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
  Future<Either<Failure, void>> deleteSubscription(String id) async {
    try {
      await _remoteDatasource.deleteSubscription(id);
      return const Right(null);
    } on NotFoundException {
      return const Left(NotFoundFailure());
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRevenueSummary(
      String academyId) async {
    try {
      final data = await _remoteDatasource.getRevenueSummary(academyId);
      return Right(data);
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
}
