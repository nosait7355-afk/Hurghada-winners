import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:hurghada_winners/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class GetCurrentUserUsecase extends UseCaseNoParams<UserEntity> {
  final AuthRepository _repository;
  GetCurrentUserUsecase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call() {
    return _repository.getCurrentUser();
  }
}
