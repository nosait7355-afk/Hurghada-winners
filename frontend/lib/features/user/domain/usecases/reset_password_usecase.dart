import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class ResetPasswordParams {
  final String id;
  final String newPassword;
  const ResetPasswordParams({required this.id, required this.newPassword});
}

/// super_admin only — resets another user's password.
class ResetPasswordUsecase extends UseCase<void, ResetPasswordParams> {
  final UserRepository _repository;

  ResetPasswordUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) {
    return _repository.resetPassword(params.id, params.newPassword);
  }
}
