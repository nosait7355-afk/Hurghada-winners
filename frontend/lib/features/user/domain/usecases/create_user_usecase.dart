import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/user/domain/entities/user_management_entity.dart';
import 'package:hurghada_winners/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class CreateUserParams {
  final String name;
  final String email;
  final String password;
  final String academyId;
  final String role;

  const CreateUserParams({
    required this.name,
    required this.email,
    required this.password,
    required this.academyId,
    this.role = 'academy_admin',
  });
}

class CreateUserUsecase
    extends UseCase<UserManagementEntity, CreateUserParams> {
  final UserRepository _repository;

  CreateUserUsecase(this._repository);

  @override
  Future<Either<Failure, UserManagementEntity>> call(
      CreateUserParams params) {
    return _repository.createUser(
      name: params.name,
      email: params.email,
      password: params.password,
      academyId: params.academyId,
      role: params.role,
    );
  }
}
