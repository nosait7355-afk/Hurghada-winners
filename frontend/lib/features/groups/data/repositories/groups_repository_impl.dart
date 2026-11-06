import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/groups/data/datasources/groups_remote_datasource.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  final GroupsRemoteDatasource _remoteDatasource;

  GroupsRepositoryImpl({required GroupsRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<
      Either<
          Failure,
          ({
            List<GroupEntity> groups,
            int total,
            int page,
            int totalPages,
          })>> getGroups({
    String? academyId,
    String? sportId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _remoteDatasource.getGroups(
        academyId: academyId,
        sportId: sportId,
        page: page,
        limit: limit,
      );
      return Right((
        groups: result.groups.map((m) => m.toEntity()).toList(),
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
  Future<Either<Failure, List<GroupEntity>>> getGroupsByAcademy({
    required String academyId,
    String? sportId,
  }) async {
    try {
      final models = await _remoteDatasource.getGroupsByAcademy(
        academyId: academyId,
        sportId: sportId,
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
  Future<Either<Failure, List<GroupEntity>>> getGroupsBySport(
      String sportId) async {
    try {
      final models = await _remoteDatasource.getGroupsBySport(sportId);
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
  Future<Either<Failure, GroupEntity>> getGroupById(String id) async {
    try {
      final model = await _remoteDatasource.getGroupById(id);
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
  Future<Either<Failure, GroupEntity>> createGroup({
    required String name,
    String? academyId,
    String? sportId,
    String? ageGroup,
    int? capacity,
  }) async {
    try {
      final model = await _remoteDatasource.createGroup(
        name: name,
        academyId: academyId,
        sportId: sportId,
        ageGroup: ageGroup,
        capacity: capacity,
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
  Future<Either<Failure, GroupEntity>> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    bool? isActive,
    String? sportId,
  }) async {
    try {
      final model = await _remoteDatasource.updateGroup(
        id: id,
        name: name,
        ageGroup: ageGroup,
        capacity: capacity,
        isActive: isActive,
        sportId: sportId,
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
  Future<Either<Failure, void>> deleteGroup(String id) async {
    try {
      await _remoteDatasource.deleteGroup(id);
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
  Future<Either<Failure, void>> reorderGroups({
    required String academyId,
    required List<String> orderedIds,
  }) async {
    try {
      await _remoteDatasource.reorderGroups(
        academyId: academyId,
        orderedIds: orderedIds,
      );
      return const Right(null);
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
