import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteGroupParams {
  final String id;

  const DeleteGroupParams({required this.id});
}

class DeleteGroupUsecase extends UseCase<void, DeleteGroupParams> {
  final GroupsRepository _repository;

  DeleteGroupUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteGroupParams params) {
    return _repository.deleteGroup(params.id);
  }
}
