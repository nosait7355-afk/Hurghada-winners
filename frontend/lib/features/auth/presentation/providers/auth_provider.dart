import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/network/token_manager.dart';
import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:hurghada_winners/features/auth/domain/repositories/auth_repository.dart';
import 'package:hurghada_winners/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:hurghada_winners/features/auth/domain/usecases/login_usecase.dart';
import 'package:hurghada_winners/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isAuthenticated;
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final LoginUsecase _loginUsecase;
  late final LogoutUsecase _logoutUsecase;
  late final GetCurrentUserUsecase _getCurrentUserUsecase;

  @override
  Future<AuthState> build() async {
    debugPrint('[AUTH] AuthNotifier.build() — checking saved token');
    _loginUsecase = sl<LoginUsecase>();
    _logoutUsecase = sl<LogoutUsecase>();
    _getCurrentUserUsecase = sl<GetCurrentUserUsecase>();
    return _checkAuthState();
  }

  Future<AuthState> _checkAuthState() async {
    // إذا كانت الجلسة الحالية للاعب فلا نحاول مصادقة المدير (توكن لاعب لا يصلح
    // لنقاط المدير). هذا يمنع تداخل جلستي المدير واللاعب على نفس الجهاز.
    final sessionType = await sl<TokenManager>().getSessionType();
    if (sessionType == 'player') {
      return const AuthState(isAuthenticated: false);
    }
    final result = await _getCurrentUserUsecase();
    return result.fold(
      (_) => const AuthState(isAuthenticated: false),
      (user) => AuthState(isAuthenticated: true, user: user),
    );
  }

  /// إعادة تحميل حالة المصادقة من التوكن المحفوظ (تُستدعى بعد التسجيل الذاتي
  /// الذي يسجّل الدخول تلقائياً ويحفظ التوكن مباشرة).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _checkAuthState());
  }

  Future<void> login({required String email, required String password}) async {
    debugPrint('[AUTH] login() called — state → loading');
    state = const AsyncValue.loading();
    final result = await _loginUsecase(LoginParams(email: email, password: password));
    state = result.fold(
      (failure) {
        debugPrint('[AUTH] login() FAILED: ${failure.message}');
        return AsyncValue.data(
          AuthState(isAuthenticated: false, errorMessage: failure.message),
        );
      },
      (user) {
        debugPrint('[AUTH] login() SUCCESS: ${user.email} role=${user.role}');
        // وسم الجلسة كـ admin (منصة Nosait) لتمييزها عن جلسة اللاعب.
        sl<TokenManager>().saveSessionType('admin');
        return AsyncValue.data(
          AuthState(isAuthenticated: true, user: user),
        );
      },
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _logoutUsecase();
    state = const AsyncValue.data(AuthState(isAuthenticated: false));
  }

  /// Update the current user's own name. Returns null on success, error otherwise.
  Future<String?> updateName(String name) async {
    final repo = sl<AuthRepository>();
    final result = await repo.updateProfile(name: name);
    return result.fold(
      (failure) => failure.message,
      (user) {
        final current = state.valueOrNull ?? const AuthState();
        state = AsyncValue.data(
          current.copyWith(isAuthenticated: true, user: user),
        );
        return null;
      },
    );
  }

  /// Change the current user's own password (verifies current password server-side).
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final repo = sl<AuthRepository>();
    final result = await repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return result.fold((failure) => failure.message, (_) => null);
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(clearError: true));
    }
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
