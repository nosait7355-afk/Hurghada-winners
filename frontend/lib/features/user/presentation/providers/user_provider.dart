import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/user/domain/entities/user_management_entity.dart';
import 'package:hurghada_winners/features/user/domain/usecases/activate_user_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/create_user_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/deactivate_user_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/delete_user_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/get_users_by_academy_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/reset_password_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/update_user_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedAcademyIdProvider = StateProvider<String>((ref) => '');

class UsersNotifier extends AsyncNotifier<List<UserManagementEntity>> {
  // تهيئة مباشرة خارج build() — تحدث مرة واحدة فقط عند إنشاء الـ Notifier
  // وليس في كل مرة يُعاد فيها build() بسبب ref.watch
  final _getUsersByAcademyUsecase = sl<GetUsersByAcademyUsecase>();
  final _createUserUsecase = sl<CreateUserUsecase>();
  final _updateUserUsecase = sl<UpdateUserUsecase>();
  final _deleteUserUsecase = sl<DeleteUserUsecase>();
  final _activateUserUsecase = sl<ActivateUserUsecase>();
  final _deactivateUserUsecase = sl<DeactivateUserUsecase>();
  final _resetPasswordUsecase = sl<ResetPasswordUsecase>();

  @override
  Future<List<UserManagementEntity>> build() async {
    final academyId = ref.watch(selectedAcademyIdProvider);
    if (academyId.isEmpty) return [];
    return _fetchUsers(academyId);
  }

  Future<List<UserManagementEntity>> _fetchUsers(String academyId) async {
    final result = await _getUsersByAcademyUsecase(
      GetUsersByAcademyParams(academyId: academyId),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (users) => users,
    );
  }

  Future<void> refresh() async {
    final academyId = ref.read(selectedAcademyIdProvider);
    if (academyId.isEmpty) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers(academyId));
  }

  Future<String?> createUser({
    required String name,
    required String email,
    required String password,
    required String academyId,
    String role = 'academy_admin',
  }) async {
    assert(() {
      // ignore: avoid_print
      print('[UsersNotifier.createUser] role="$role"');
      return true;
    }());
    final result = await _createUserUsecase(
      CreateUserParams(
        name: name,
        email: email,
        password: password,
        academyId: academyId,
        role: role,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> updateUser({
    required String id,
    String? name,
    String? email,
  }) async {
    final result = await _updateUserUsecase(
      UpdateUserParams(id: id, name: name, email: email),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> deleteUser(String id) async {
    final result = await _deleteUserUsecase(DeleteUserParams(id: id));
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> activateUser(String id) async {
    final result = await _activateUserUsecase(ActivateUserParams(id: id));
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> deactivateUser(String id) async {
    final result =
        await _deactivateUserUsecase(DeactivateUserParams(id: id));
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  /// super_admin only — reset another user's password. No list refresh needed.
  Future<String?> resetPassword(String id, String newPassword) async {
    final result = await _resetPasswordUsecase(
      ResetPasswordParams(id: id, newPassword: newPassword),
    );
    return result.fold(
      (failure) => failure.message,
      (_) => null,
    );
  }
}

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<UserManagementEntity>>(
  UsersNotifier.new,
);
