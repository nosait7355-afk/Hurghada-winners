import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/player/data/datasources/player_remote_datasource.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerRemoteDatasource _remoteDatasource;

  PlayerRepositoryImpl({required PlayerRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<
      Either<
          Failure,
          ({
            List<PlayerEntity> players,
            int total,
            int page,
            int totalPages,
          })>> getPlayers({
    String? academyId,
    String? search,
    int? birthYear,
    String? sport,
    String? attendanceDay,
    bool? hasAccount,
    String? groupId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _remoteDatasource.getPlayers(
        academyId: academyId,
        search: search,
        birthYear: birthYear,
        sport: sport,
        attendanceDay: attendanceDay,
        hasAccount: hasAccount,
        groupId: groupId,
        page: page,
        limit: limit,
      );
      return Right((
        players: result.players.map((m) => m.toEntity()).toList(),
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
  Future<Either<Failure, List<PlayerEntity>>> searchPlayers(
      String query) async {
    try {
      final models = await _remoteDatasource.searchPlayers(query);
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
  Future<Either<Failure, List<PlayerEntity>>> getPlayersBirthdays({
    required int month,
    String? academyId,
  }) async {
    try {
      final models = await _remoteDatasource.getPlayersBirthdays(
        month: month,
        academyId: academyId,
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
  Future<Either<Failure, PlayerEntity>> getPlayerById(String id) async {
    try {
      final model = await _remoteDatasource.getPlayerById(id);
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
  Future<Either<Failure, PlayerEntity>> createPlayer({
    required String fullName,
    required DateTime birthDate,
    required String parentName,
    required String parentRelationship,
    String? parentJob,
    required String parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String> attendanceDays = const [],
    String? academyId,
    required String imagePath,
    required String receiptPath,
    String? groupId,
  }) async {
    try {
      final model = await _remoteDatasource.createPlayer(
        fullName: fullName,
        birthDate: birthDate,
        parentName: parentName,
        parentRelationship: parentRelationship,
        parentJob: parentJob,
        parentPhone: parentPhone,
        playerPhone: playerPhone,
        notes: notes,
        sport: sport,
        attendanceDays: attendanceDays,
        academyId: academyId,
        imagePath: imagePath,
        receiptPath: receiptPath,
        groupId: groupId,
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
  Future<Either<Failure, PlayerEntity>> updatePlayer({
    required String id,
    String? fullName,
    DateTime? birthDate,
    String? parentName,
    String? parentRelationship,
    String? parentJob,
    String? parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String>? attendanceDays,
    String? imagePath,
    String? groupId,
  }) async {
    try {
      final model = await _remoteDatasource.updatePlayer(
        id: id,
        fullName: fullName,
        birthDate: birthDate,
        parentName: parentName,
        parentRelationship: parentRelationship,
        parentJob: parentJob,
        parentPhone: parentPhone,
        playerPhone: playerPhone,
        notes: notes,
        sport: sport,
        attendanceDays: attendanceDays,
        imagePath: imagePath,
        groupId: groupId,
      );
      return Right(model.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
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
  Future<Either<Failure, void>> deletePlayer(String id) async {
    try {
      await _remoteDatasource.deletePlayer(id);
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
  Future<Either<Failure, void>> deletePlayerImage(String id) async {
    try {
      await _remoteDatasource.deletePlayerImage(id);
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
}
