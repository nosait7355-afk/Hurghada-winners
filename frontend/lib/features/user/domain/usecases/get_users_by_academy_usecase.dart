import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/user/domain/entities/user_management_entity.dart';
import 'package:hurghada_winners/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class GetUsersByAcademyParams {
  final String academyId;
  const GetUsersByAcademyParams({required this.academyId});
}

class GetUsersByAcademyUsecase
    extends UseCase<List<UserManagementEntity>, GetUsersByAcademyParams> {
  final UserRepository _repository;

  GetUsersByAcademyUsecase(this._repository);

  @override
  Future<Either<Failure, List<UserManagementEntity>>> call(
      GetUsersByAcademyParams params) {
    return _repository.getUsersByAcademy(params.academyId);
  }
}
