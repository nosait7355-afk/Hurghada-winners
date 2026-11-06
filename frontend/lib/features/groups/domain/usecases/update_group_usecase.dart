import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateGroupParams {
  final String id;
  final String? name;
  final String? ageGroup;
  final int? capacity;
  final bool? isActive;
  final String? sportId;

  const UpdateGroupParams({
    required this.id,
    this.name,
    this.ageGroup,
    this.capacity,
    this.isActive,
    this.sportId,
  });
}

class UpdateGroupUsecase extends UseCase<GroupEntity, UpdateGroupParams> {
  final GroupsRepository _repository;

  UpdateGroupUsecase(this._repository);

  @override
  Future<Either<Failure, GroupEntity>> call(UpdateGroupParams params) {
    return _repository.updateGroup(
      id: params.id,
      name: params.name,
      ageGroup: params.ageGroup,
      capacity: params.capacity,
      isActive: params.isActive,
      sportId: params.sportId,
    );
  }
}
