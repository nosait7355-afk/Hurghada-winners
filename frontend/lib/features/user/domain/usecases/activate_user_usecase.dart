import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class ActivateUserParams {
  final String id;
  const ActivateUserParams({required this.id});
}

class ActivateUserUsecase extends UseCase<void, ActivateUserParams> {
  final UserRepository _repository;

  ActivateUserUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(ActivateUserParams params) {
    return _repository.activateUser(params.id);
  }
}
