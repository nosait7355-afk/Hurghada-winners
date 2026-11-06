import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:hurghada_winners/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class LoginUsecase extends UseCase<UserEntity, LoginParams> {
  final AuthRepository _repository;
  LoginUsecase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) {
    return _repository.login(email: params.email, password: params.password);
  }
}

class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
