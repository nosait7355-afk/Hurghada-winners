import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/network/token_manager.dart';
import 'package:hurghada_winners/features/player_portal/data/player_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حالة جلسة اللاعب.
class PlayerSessionState {
  final bool isAuthenticated;
  final Map<String, dynamic>? player; // بيانات اللاعب من /me أو /login
  final String? errorMessage;

  const PlayerSessionState({
    this.isAuthenticated = false,
    this.player,
    this.errorMessage,
  });
}

class PlayerSessionNotifier extends AsyncNotifier<PlayerSessionState> {
  late final PlayerApiService _service;

  @override
  Future<PlayerSessionState> build() async {
    _service = sl<PlayerApiService>();
    // نتحقق فقط إذا كانت الجلسة المحفوظة للاعب.
    final sessionType = await sl<TokenManager>().getSessionType();
    if (sessionType != 'player') {
      return const PlayerSessionState(isAuthenticated: false);
    }
    try {
      final data = await _service.me();
      return PlayerSessionState(isAuthenticated: true, player: data);
    } catch (_) {
      return const PlayerSessionState(isAuthenticated: false);
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.login(username: username, password: password);
      state = AsyncValue.data(PlayerSessionState(isAuthenticated: true, player: data));
    } catch (e) {
      state = AsyncValue.data(
        PlayerSessionState(isAuthenticated: false, errorMessage: _msg(e)),
      );
    }
  }

  /// يُستدعى بعد إرسال طلب انضمام جديد بنجاح (التوكن يكون محفوظاً بالفعل عبر
  /// PlayerApiService.submitJoinRequest) — يعيد جلب بيانات الجلسة الرسمية
  /// (/auth/player/me) بدل الاعتماد على استجابة الإنشاء المختلفة الشكل.
  Future<void> refreshFromToken() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.me();
      state = AsyncValue.data(PlayerSessionState(isAuthenticated: true, player: data));
    } catch (e) {
      state = AsyncValue.data(
        PlayerSessionState(isAuthenticated: false, errorMessage: _msg(e)),
      );
    }
  }

  /// تبديل لحساب آخر في العائلة. عند الفشل تبقى الجلسة الحالية كما هي
  /// ويُعاد الخطأ للواجهة.
  Future<void> switchTo(String accountId) async {
    final data = await _service.switchAccount(accountId);
    state = AsyncValue.data(PlayerSessionState(isAuthenticated: true, player: data));
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _service.logout();
    state = const AsyncValue.data(PlayerSessionState(isAuthenticated: false));
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        PlayerSessionState(
          isAuthenticated: current.isAuthenticated,
          player: current.player,
        ),
      );
    }
  }

  String _msg(Object e) {
    if (e is AppException) return e.message;
    return 'فشل تسجيل الدخول';
  }
}

final playerSessionProvider =
    AsyncNotifierProvider<PlayerSessionNotifier, PlayerSessionState>(
  PlayerSessionNotifier.new,
);
