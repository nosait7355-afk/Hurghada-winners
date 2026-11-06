import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class GetGroupsByAcademyParams {
  final String academyId;
  final String? sportId;

  const GetGroupsByAcademyParams({required this.academyId, this.sportId});
}

class GetGroupsByAcademyUsecase
    extends UseCase<List<GroupEntity>, GetGroupsByAcademyParams> {
  final GroupsRepository _repository;

  GetGroupsByAcademyUsecase(this._repository);

  @override
  Future<Either<Failure, List<GroupEntity>>> call(
      GetGroupsByAcademyParams params) {
    return _repository.getGroupsByAcademy(
      academyId: params.academyId,
      sportId: params.sportId,
    );
  }
}
