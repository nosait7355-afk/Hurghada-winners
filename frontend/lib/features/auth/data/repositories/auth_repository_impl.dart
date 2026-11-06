import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/network/token_manager.dart';
import 'package:hurghada_winners/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:hurghada_winners/features/auth/data/models/user_model.dart';
import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:hurghada_winners/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final TokenManager _tokenManager;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required TokenManager tokenManager,
  })  : _remoteDatasource = remoteDatasource,
        _tokenManager = tokenManager;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    debugPrint('[REPO] login() → calling API');
    try {
      final result = await _remoteDatasource.login(email: email, password: password);
      debugPrint('[REPO] login() → API returned, parsing response');
      final token = result['token'] as String?;
      final refreshToken = result['refreshToken'] as String?;
      final userData = result['data'] as Map<String, dynamic>?;

      debugPrint('[REPO] login() → token=${token != null ? "EXISTS(${token.length}chars)" : "NULL"} userData=${userData != null ? "EXISTS" : "NULL"}');

      if (token == null || userData == null) {
        debugPrint('[REPO] login() → FAIL: token or userData is null');
        return const Left(ServerFailure(message: 'استجابة غير صحيحة من الخادم'));
      }

      debugPrint('[REPO] login() → saving token to secure storage...');
      await _tokenManager.saveToken(token);
      debugPrint('[REPO] login() → TOKEN SAVED ✓');

      if (refreshToken != null) {
        await _tokenManager.saveRefreshToken(refreshToken);
        debugPrint('[REPO] login() → refresh token saved ✓');
      }

      final user = UserModel.fromJson(userData);
      debugPrint('[REPO] login() → user parsed: ${user.email} role=${user.role} academyId=${user.academyId}');
      debugPrint('[REPO] login() → LOGIN SUCCESS ✓');
      return Right(user.toEntity());
    } on UnauthorizedException catch (e) {
      debugPrint('[REPO] login() → UnauthorizedException: ${e.message}');
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException {
      debugPrint('[REPO] login() → NetworkException');
      return const Left(NetworkFailure());
    } on TimeoutException {
      debugPrint('[REPO] login() → TimeoutException');
      return const Left(TimeoutFailure());
    } on AppException catch (e) {
      debugPrint('[REPO] login() → AppException: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      debugPrint('[REPO] login() → Unknown exception: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDatasource.logout();
    } catch (_) {
      // ignore logout API errors
    } finally {
      await _tokenManager.clearToken();
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    debugPrint('[REPO] getCurrentUser() → checking token first...');
    final hasToken = await _tokenManager.hasToken();
    debugPrint('[REPO] getCurrentUser() → hasToken=$hasToken');
    if (!hasToken) {
      debugPrint('[REPO] getCurrentUser() → no token, returning UnauthorizedFailure');
      return const Left(UnauthorizedFailure());
    }
    debugPrint('[REPO] getCurrentUser() → calling GET /auth/me...');
    try {
      final user = await _remoteDatasource.getCurrentUser();
      debugPrint('[REPO] getCurrentUser() → SUCCESS: ${user.email}');
      return Right(user.toEntity());
    } on UnauthorizedException {
      debugPrint('[REPO] getCurrentUser() → 401 Unauthorized');
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      debugPrint('[REPO] getCurrentUser() → NetworkException');
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      debugPrint('[REPO] getCurrentUser() → AppException: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      debugPrint('[REPO] getCurrentUser() → Unknown: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile(
      {required String name}) async {
    try {
      final user = await _remoteDatasource.updateProfile(name: name);
      return Right(user.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDatasource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _tokenManager.hasToken();
  }
}
