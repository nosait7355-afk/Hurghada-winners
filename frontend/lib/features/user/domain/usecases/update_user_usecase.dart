import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/user/domain/entities/user_management_entity.dart';
import 'package:hurghada_winners/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateUserParams {
  final String id;
  final String? name;
  final String? email;

  const UpdateUserParams({
    required this.id,
    this.name,
    this.email,
  });
}

class UpdateUserUsecase
    extends UseCase<UserManagementEntity, UpdateUserParams> {
  final UserRepository _repository;

  UpdateUserUsecase(this._repository);

  @override
  Future<Either<Failure, UserManagementEntity>> call(
      UpdateUserParams params) {
    return _repository.updateUser(
      id: params.id,
      name: params.name,
      email: params.email,
    );
  }
}
