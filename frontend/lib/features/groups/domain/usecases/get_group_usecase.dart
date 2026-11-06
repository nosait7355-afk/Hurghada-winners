import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class GetGroupParams {
  final String id;

  const GetGroupParams({required this.id});
}

class GetGroupUsecase extends UseCase<GroupEntity, GetGroupParams> {
  final GroupsRepository _repository;

  GetGroupUsecase(this._repository);

  @override
  Future<Either<Failure, GroupEntity>> call(GetGroupParams params) {
    return _repository.getGroupById(params.id);
  }
}
