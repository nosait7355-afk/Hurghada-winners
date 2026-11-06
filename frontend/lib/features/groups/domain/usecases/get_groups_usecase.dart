import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class GetGroupsParams {
  final String? academyId;
  final String? sportId;
  final int page;
  final int limit;

  const GetGroupsParams({
    this.academyId,
    this.sportId,
    this.page = 1,
    this.limit = 20,
  });
}

class GetGroupsUsecase extends UseCase<
    ({List<GroupEntity> groups, int total, int page, int totalPages}),
    GetGroupsParams> {
  final GroupsRepository _repository;

  GetGroupsUsecase(this._repository);

  @override
  Future<Either<Failure, ({List<GroupEntity> groups, int total, int page, int totalPages})>>
      call(GetGroupsParams params) {
    return _repository.getGroups(
      academyId: params.academyId,
      sportId: params.sportId,
      page: params.page,
      limit: params.limit,
    );
  }
}
