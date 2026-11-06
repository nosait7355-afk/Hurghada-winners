import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class CreateGroupParams {
  final String name;
  final String? academyId;
  final String? sportId;
  final String? ageGroup;
  final int? capacity;

  const CreateGroupParams({
    required this.name,
    this.academyId,
    this.sportId,
    this.ageGroup,
    this.capacity,
  });
}

class CreateGroupUsecase extends UseCase<GroupEntity, CreateGroupParams> {
  final GroupsRepository _repository;

  CreateGroupUsecase(this._repository);

  @override
  Future<Either<Failure, GroupEntity>> call(CreateGroupParams params) {
    return _repository.createGroup(
      name: params.name,
      academyId: params.academyId,
      sportId: params.sportId,
      ageGroup: params.ageGroup,
      capacity: params.capacity,
    );
  }
}
