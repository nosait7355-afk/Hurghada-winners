import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class LogoutUsecase extends UseCaseNoParams<void> {
  final AuthRepository _repository;
  LogoutUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}
