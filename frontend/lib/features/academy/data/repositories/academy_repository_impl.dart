import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:hurghada_winners/features/academy/domain/entities/academy_entity.dart';
import 'package:hurghada_winners/features/academy/domain/repositories/academy_repository.dart';
import 'package:dartz/dartz.dart';

class AcademyRepositoryImpl implements AcademyRepository {
  final AcademyRemoteDatasource _remoteDatasource;

  AcademyRepositoryImpl({required AcademyRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<AcademyEntity>>> getAcademies() async {
    try {
      final models = await _remoteDatasource.getAcademies();
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
  Future<Either<Failure, AcademyEntity>> getAcademyById(String id) async {
    try {
      final model = await _remoteDatasource.getAcademyById(id);
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
  Future<Either<Failure, AcademyEntity>> createAcademy({
    required String name,
    required String phone,
    required String address,
    String currency = 'EGP',
    List<String> sports = const [],
    String? logoUrl,
  }) async {
    try {
      final model = await _remoteDatasource.createAcademy({
        'name': name,
        'phone': phone,
        'address': address,
        'currency': currency,
        if (sports.isNotEmpty) 'sports': sports,
        if (logoUrl != null) 'logo_url': logoUrl,
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
  Future<Either<Failure, AcademyEntity>> updateAcademy({
    required String id,
    required String name,
    required String phone,
    required String address,
    String currency = 'EGP',
    List<String> sports = const [],
    String? logoUrl,
    String? websiteUrl,
    String? facebookUrl,
    String? tiktokUrl,
    String? instagramUrl,
  }) async {
    try {
      final model = await _remoteDatasource.updateAcademy(id, {
        'name': name,
        'phone': phone,
        'address': address,
        'currency': currency,
        if (sports.isNotEmpty) 'sports': sports,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (websiteUrl != null) 'websiteUrl': websiteUrl,
        if (facebookUrl != null) 'facebookUrl': facebookUrl,
        if (tiktokUrl != null) 'tiktokUrl': tiktokUrl,
        if (instagramUrl != null) 'instagramUrl': instagramUrl,
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
  Future<Either<Failure, void>> deleteAcademy(String id) async {
    try {
      await _remoteDatasource.deleteAcademy(id);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
