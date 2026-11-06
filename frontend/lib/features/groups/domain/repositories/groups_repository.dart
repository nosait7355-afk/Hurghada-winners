import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:dartz/dartz.dart';

abstract class GroupsRepository {
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
  });

  Future<Either<Failure, List<GroupEntity>>> getGroupsByAcademy({
    required String academyId,
    String? sportId,
  });

  Future<Either<Failure, List<GroupEntity>>> getGroupsBySport(String sportId);

  Future<Either<Failure, GroupEntity>> getGroupById(String id);

  Future<Either<Failure, GroupEntity>> createGroup({
    required String name,
    String? academyId,
    String? sportId,
    String? ageGroup,
    int? capacity,
  });

  Future<Either<Failure, GroupEntity>> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    bool? isActive,
    String? sportId,
  });

  Future<Either<Failure, void>> deleteGroup(String id);

  Future<Either<Failure, void>> reorderGroups({
    required String academyId,
    required List<String> orderedIds,
  });
}
