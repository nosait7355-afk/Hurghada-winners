import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/academy/domain/repositories/academy_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteAcademyParams {
  final String id;
  const DeleteAcademyParams({required this.id});
}

class DeleteAcademyUsecase extends UseCase<void, DeleteAcademyParams> {
  final AcademyRepository _repository;
  DeleteAcademyUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteAcademyParams params) {
    return _repository.deleteAcademy(params.id);
  }
}
