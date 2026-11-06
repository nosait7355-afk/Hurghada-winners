import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/evaluation/data/datasources/evaluation_remote_datasource.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class EvaluationRepositoryImpl implements EvaluationRepository {
  final EvaluationRemoteDatasource _remoteDatasource;

  EvaluationRepositoryImpl(
      {required EvaluationRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<
      Either<
          Failure,
          ({
            List<EvaluationEntity> evaluations,
            int total,
            int page,
            int totalPages,
          })>> getEvaluationsByPlayer({
    required String playerId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await _remoteDatasource.getEvaluationsByPlayer(
        playerId: playerId,
        page: page,
        limit: limit,
      );
      return Right((
        evaluations: result.evaluations.map((m) => m.toEntity()).toList(),
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
  Future<Either<Failure, EvaluationEntity?>> getLatestEvaluation(
      String playerId) async {
    try {
      final model = await _remoteDatasource.getLatestEvaluation(playerId);
      return Right(model?.toEntity());
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
  Future<Either<Failure, EvaluationEntity>> getEvaluationById(
      String id) async {
    try {
      final model = await _remoteDatasource.getEvaluationById(id);
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
  Future<Either<Failure, EvaluationEntity>> createEvaluation({
    required String playerId,
    required double fitness,
    required double basicSkills,
    required double attack,
    required double defense,
    required double commitment,
    String? notes,
    String? academyId,
    DateTime? evaluationDate,
  }) async {
    try {
      final model = await _remoteDatasource.createEvaluation(
        playerId: playerId,
        fitness: fitness,
        basicSkills: basicSkills,
        attack: attack,
        defense: defense,
        commitment: commitment,
        notes: notes,
        academyId: academyId,
        evaluationDate: evaluationDate,
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
  Future<Either<Failure, EvaluationEntity>> updateEvaluation({
    required String id,
    double? fitness,
    double? basicSkills,
    double? attack,
    double? defense,
    double? commitment,
    String? notes,
    DateTime? evaluationDate,
  }) async {
    try {
      final model = await _remoteDatasource.updateEvaluation(
        id: id,
        fitness: fitness,
        basicSkills: basicSkills,
        attack: attack,
        defense: defense,
        commitment: commitment,
        notes: notes,
        evaluationDate: evaluationDate,
      );
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
  Future<Either<Failure, void>> deleteEvaluation(String id) async {
    try {
      await _remoteDatasource.deleteEvaluation(id);
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
  Future<
      Either<
          Failure,
          ({
            List<EvaluationEntity> evaluations,
            int total,
            int page,
            int totalPages,
          })>> getEvaluationsByAcademy({
    required String academyId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final result = await _remoteDatasource.getEvaluationsByAcademy(
        academyId: academyId,
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
      );
      return Right((
        evaluations: result.evaluations.map((m) => m.toEntity()).toList(),
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
}
