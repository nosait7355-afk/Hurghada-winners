import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/academy/domain/entities/academy_entity.dart';
import 'package:hurghada_winners/features/academy/domain/repositories/academy_repository.dart';
import 'package:dartz/dartz.dart';

class GetAcademyParams {
  final String id;
  const GetAcademyParams({required this.id});
}

class GetAcademyUsecase extends UseCase<AcademyEntity, GetAcademyParams> {
  final AcademyRepository _repository;
  GetAcademyUsecase(this._repository);

  @override
  Future<Either<Failure, AcademyEntity>> call(GetAcademyParams params) {
    return _repository.getAcademyById(params.id);
  }
}
