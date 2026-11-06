import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/user/data/datasources/user_remote_datasource.dart';
import 'package:hurghada_winners/features/user/domain/entities/user_management_entity.dart';
import 'package:hurghada_winners/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource _remoteDatasource;

  UserRepositoryImpl({required UserRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<UserManagementEntity>>> getUsersByAcademy(
      String academyId) async {
    try {
      final models = await _remoteDatasource.getUsersByAcademy(academyId);
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
  Future<Either<Failure, UserManagementEntity>> getUserById(String id) async {
    try {
      final model = await _remoteDatasource.getUserById(id);
      return Right(model.toEntity());
    } on NotFoundException {
      return const Left(NotFoundFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserManagementEntity>> createUser({
    required String name,
    required String email,
    required String password,
    required String academyId,
    String role = 'academy_admin',
  }) async {
    try {
      final model = await _remoteDatasource.createUser({
        'name': name,
        'email': email,
        'password': password,
        'academyId': academyId,
        'role': role,
      });
      return Right(model.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserManagementEntity>> updateUser({
    required String id,
    String? name,
    String? email,
  }) async {
    try {
      final model = await _remoteDatasource.updateUser(id, {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      });
      return Right(model.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String id) async {
    try {
      await _remoteDatasource.deleteUser(id);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> activateUser(String id) async {
    try {
      await _remoteDatasource.activateUser(id);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deactivateUser(String id) async {
    try {
      await _remoteDatasource.deactivateUser(id);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
      String id, String newPassword) async {
    try {
      await _remoteDatasource.resetPassword(id, newPassword);
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
