import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class DeactivateUserParams {
  final String id;
  const DeactivateUserParams({required this.id});
}

class DeactivateUserUsecase extends UseCase<void, DeactivateUserParams> {
  final UserRepository _repository;

  DeactivateUserUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeactivateUserParams params) {
    return _repository.deactivateUser(params.id);
  }
}
