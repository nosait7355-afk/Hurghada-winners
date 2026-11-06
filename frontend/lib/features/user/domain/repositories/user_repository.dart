import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/user/domain/entities/user_management_entity.dart';
import 'package:dartz/dartz.dart';

abstract class UserRepository {
  Future<Either<Failure, List<UserManagementEntity>>> getUsersByAcademy(
      String academyId);

  Future<Either<Failure, UserManagementEntity>> getUserById(String id);

  Future<Either<Failure, UserManagementEntity>> createUser({
    required String name,
    required String email,
    required String password,
    required String academyId,
    String role = 'academy_admin',
  });

  Future<Either<Failure, UserManagementEntity>> updateUser({
    required String id,
    String? name,
    String? email,
  });

  Future<Either<Failure, void>> deleteUser(String id);

  Future<Either<Failure, void>> activateUser(String id);

  Future<Either<Failure, void>> deactivateUser(String id);

  Future<Either<Failure, void>> resetPassword(String id, String newPassword);
}
