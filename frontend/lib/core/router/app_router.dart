import 'package:hurghada_winners/core/navigation/app_navigator.dart';
import 'package:hurghada_winners/core/refresh/page_refresh.dart';
import 'package:hurghada_winners/features/academy/presentation/screens/academy_detail_screen.dart';
import 'package:hurghada_winners/features/reports/presentation/screens/reports_screen.dart';
import 'package:hurghada_winners/features/academy/presentation/screens/academy_list_screen.dart';
import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/auth/presentation/screens/account_settings_screen.dart';
import 'package:hurghada_winners/features/auth/presentation/screens/login_screen.dart';
import 'package:hurghada_winners/features/welcome/presentation/screens/welcome_screen.dart';
import 'package:hurghada_winners/features/academy_registration/presentation/screens/academy_registration_wizard_screen.dart';
import 'package:hurghada_winners/features/chat/presentation/screens/academy_conversations_screen.dart';
import 'package:hurghada_winners/features/academy_album/presentation/screens/academy_album_screen.dart';
import 'package:hurghada_winners/features/academy_album/presentation/screens/player_album_screen.dart';
import 'package:hurghada_winners/features/player_videos/presentation/screens/my_videos_screen.dart';
import 'package:hurghada_winners/features/player_videos/presentation/screens/player_videos_screen.dart';
import 'package:hurghada_winners/features/store/presentation/screens/store_management_screen.dart';
import 'package:hurghada_winners/features/matches/presentation/screens/matches_list_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/tournaments_list_screen.dart';
import 'package:hurghada_winners/features/store/presentation/screens/player_store_screen.dart';
import 'package:hurghada_winners/features/team_kit/presentation/screens/kit_management_screen.dart';
import 'package:hurghada_winners/features/team_kit/presentation/screens/player_team_kit_screen.dart';
import 'package:hurghada_winners/features/offers/presentation/screens/offers_management_screen.dart';
import 'package:hurghada_winners/features/offers/presentation/screens/player_offers_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/player_tournaments_screen.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:hurghada_winners/features/player_portal/presentation/screens/player_login_screen.dart';
import 'package:hurghada_winners/features/player_portal/presentation/screens/player_dashboard_screen.dart';
import 'package:hurghada_winners/features/player_portal/presentation/screens/player_chat_screen.dart';
import 'package:hurghada_winners/features/player_portal/presentation/screens/player_notifications_screen.dart';
import 'package:hurghada_winners/features/player_portal/presentation/screens/player_join_request_wizard_screen.dart';
import 'package:hurghada_winners/features/player_portal/presentation/screens/player_pending_approval_screen.dart';
import 'package:hurghada_winners/features/player/presentation/screens/join_requests_list_screen.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_birthdays_screen.dart';
import 'package:hurghada_winners/features/player/presentation/screens/join_request_detail_screen.dart';
import 'package:hurghada_winners/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:hurghada_winners/features/evaluation/presentation/screens/evaluation_history_screen.dart';
import 'package:hurghada_winners/features/notification/presentation/screens/notifications_screen.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_detail_screen.dart';
import 'package:hurghada_winners/features/player/presentation/screens/players_list_screen.dart';
import 'package:hurghada_winners/features/groups/presentation/screens/groups_list_screen.dart';
import 'package:hurghada_winners/features/splash/presentation/screens/splash_screen.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/player_subscription_history_screen.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/subscriptions_list_screen.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/renewal_requests_screen.dart';
import 'package:hurghada_winners/features/player/presentation/screens/public_player_profile_screen.dart';
import 'package:hurghada_winners/features/family/presentation/screens/families_screen.dart';
import 'package:hurghada_winners/features/user/presentation/screens/users_list_screen.dart';
import 'package:hurghada_winners/features/staff/presentation/screens/staff_list_screen.dart';
import 'package:hurghada_winners/features/payroll/presentation/screens/payroll_list_screen.dart';
import 'package:hurghada_winners/features/expenses/presentation/screens/expenses_list_screen.dart';
import 'package:hurghada_winners/features/info/presentation/screens/branches_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String registerAcademy = '/register-academy';
  static const String branches = '/branches';
  static const String playerLogin = '/player-login';
  static const String playerJoinRequest = '/player-join-request';
  static const String playerPendingApproval = '/player/pending-approval';
  static const String playerDashboard = '/player';
  static const String playerChat = '/player/chat';
  static const String playerNotifications = '/player/notifications';
  static const String playerAlbum = '/player/album';
  static const String playerMyVideos = '/player/videos';
  static const String playerStore = '/player/store';
  static const String playerTeamKit = '/player/team-kit';
  static const String playerOffers = '/player/offers';
  static const String playerTournaments = '/player/tournaments';
  static const String academyAlbum = '/academy-album';
  static const String academyStore = '/store';
  static const String academyTeamKit = '/team-kit';
  static const String academyOffers = '/offers';
  static const String academyChat = '/chat';
  static const String home = '/home';
  static const String academyList = '/academies';
  static const String academyDetail = '/academies/:id';
  static const String academyUsers = '/academies/:id/users';
  static const String playersList = '/academies/:id/players';
  static const String joinRequests = '/academies/:id/join-requests';
  static const String playerBirthdays = '/academies/:id/birthdays';
  static const String joinRequestDetail = '/academies/:id/join-requests/:requestId';
  static const String groupsList = '/academies/:id/groups';
  static const String matchesList = '/academies/:id/matches';
  static const String tournamentsList = '/academies/:id/tournaments';
  static const String subscriptionsList = '/academies/:id/subscriptions';
  static const String playerDetail = '/academies/:id/players/:playerId';
  static const String playerSubscriptions =
      '/academies/:id/players/:playerId/subscriptions';
  static const String playerEvaluations =
      '/academies/:id/players/:playerId/evaluations';
  static const String playerVideos =
      '/academies/:id/players/:playerId/videos';
  static const String dashboard = '/dashboard';
  static const String reports = '/reports';
  static const String staffList = '/academies/:id/staff';
  static const String payrollList = '/academies/:id/payroll';
  static const String expensesList = '/academies/:id/expenses';
  static const String notifications = '/notifications';
  static const String accountSettings = '/account-settings';
  static const String renewalRequests = '/renewal-requests';
  // صفحة بروفايل اللاعب العامة (رابط مشاركة) — متاحة للجميع بلا دخول.
  static const String publicPlayerProfile = '/p/:token';
  // تبويب "إضافة عائلة" — دمج حسابات لاعبين (سوبر أدمن فقط).
  static const String families = '/families';
}

// RouterNotifier يُبلِّغ GoRouter عند تغيّر حالة المصادقة
// بدلاً من إعادة إنشاء GoRouter كل مرة (كان يُسبب عودة Splash)
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    debugPrint('[ROUTER] _RouterNotifier created — GoRouter instance #${identityHashCode(this)}');
    _ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      debugPrint('[ROUTER] authState changed: ${prev.runtimeType} → ${next.runtimeType} | isLoading=${next.isLoading} | isAuthenticated=${next.valueOrNull?.isAuthenticated}');
      notifyListeners();
    });
    // نستمع أيضاً لجلسة اللاعب (Nosait) حتى يُعيد GoRouter تقييم التوجيه
    // عند دخول/خروج اللاعب — دون إعادة إنشاء الراوتر إطلاقاً.
    _ref.listen<AsyncValue<PlayerSessionState>>(playerSessionProvider, (prev, next) {
      notifyListeners();
    });
  }

  // مسارات عامة لا تتطلب مصادقة (منصة Nosait).
  static const _publicRoutes = {
    AppRoutes.welcome,
    AppRoutes.login,
    AppRoutes.registerAcademy,
    AppRoutes.playerLogin,
    AppRoutes.playerJoinRequest,
    AppRoutes.branches,
  };

  String? _adminHome(UserEntity? user) {
    if (user?.isAdmin == true && user?.academyId != null) {
      return AppRoutes.playersList.replaceFirst(':id', user!.academyId!);
    }
    // حساب إداري بلا صلاحيات إحصائيات: لوحة المعلومات مقفولة عليه،
    // فتكون قائمة الأكاديميات هي صفحته الرئيسية.
    if (user?.canViewReports == false) return AppRoutes.academyList;
    return AppRoutes.home;
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final isLoggedIn = authAsync.valueOrNull?.isAuthenticated ?? false;
    final user = authAsync.valueOrNull?.user;

    final playerAsync = _ref.read(playerSessionProvider);
    final playerLoggedIn = playerAsync.valueOrNull?.isAuthenticated ?? false;

    final loc = state.matchedLocation;
    debugPrint('[ROUTER] redirect() loc=$loc admin=$isLoggedIn player=$playerLoggedIn');

    // الـ Splash يدير انتقاله بنفسه.
    if (loc == AppRoutes.splash) return null;

    // رابط المشاركة العام يُفتح كما هو لأي زائر — مسجّل أو لا، مدير أو لاعب.
    if (loc.startsWith('/p/')) return null;

    // ── جلسة اللاعب لها الأولوية ──
    if (playerLoggedIn) {
      // طلبات الانضمام الذاتية المعلّقة/المرفوضة: تُحجب كل شاشات البوابة
      // وتُوجَّه دائماً لشاشة "طلبك قيد المراجعة" — الباك إند أصلاً يمنع أي
      // استدعاء API آخر غير /me لنفس السبب (طبقة حماية مطابقة).
      final status = playerAsync.valueOrNull?.player?['registrationStatus'] as String? ?? 'approved';
      if (status != 'approved') {
        if (loc != AppRoutes.playerPendingApproval) return AppRoutes.playerPendingApproval;
        return null;
      }
      if (loc == AppRoutes.playerPendingApproval) return AppRoutes.playerDashboard;
      if (!loc.startsWith('/player')) return AppRoutes.playerDashboard;
      return null;
    }

    // ── جلسة المدير/السوبر أدمن ──
    if (isLoggedIn) {
      // على مسار عام → توجيه لواجهة المدير المناسبة.
      if (_publicRoutes.contains(loc)) return _adminHome(user);

      // دور admin الفرعي مُقيَّد (كما كان) باللاعبين + الإشعارات + الإعدادات.
      if (user?.isAdmin == true) {
        final academyId = user?.academyId;
        final allowedPrefixes = [
          '/academies/${academyId ?? ''}/players',
          '/academies/${academyId ?? ''}/groups',
          '/academies/${academyId ?? ''}/join-requests',
          AppRoutes.notifications,
          AppRoutes.accountSettings,
        ];
        final isAllowed = academyId != null &&
            allowedPrefixes.any((prefix) => loc.startsWith(prefix));
        if (!isAllowed && academyId != null) {
          return AppRoutes.playersList.replaceFirst(':id', academyId);
        }
      }

      // الإحصائيات والتقارير والبيانات المالية مقفولة على الحسابات الإدارية
      // المحدودة. ملاحظة: /home و /dashboard كلاهما يعرض DashboardScreen، فلا
      // بد من سدّ الاثنين — وإلا صار /dashboard باباً خلفياً للوحة الإحصائيات.
      // الرواتب والمصروفات مساران متداخلان (/academies/:id/…) فنطابق باللاحقة.
      if (user?.canViewReports == false &&
          (loc.startsWith(AppRoutes.reports) ||
              loc.startsWith(AppRoutes.home) ||
              loc.startsWith(AppRoutes.dashboard) ||
              loc.endsWith('/payroll') ||
              loc.endsWith('/expenses'))) {
        return AppRoutes.academyList;
      }

      // طلبات التجديد يراجعها السوبر أدمن فقط (والباك إند يفرض ذلك أيضاً).
      if ((loc.startsWith(AppRoutes.renewalRequests) ||
              loc.startsWith(AppRoutes.families)) &&
          user?.isSuperAdmin != true) {
        return _adminHome(user);
      }

      // لوحة اشتراكات المنصة لـ super_admin فقط.
      if (loc.startsWith('/platform') && user?.isSuperAdmin != true) {
        return _adminHome(user);
      }
      return null;
    }

    // ── غير مسجّل إطلاقاً → شاشة الترحيب ما لم يكن على مسار عام ──
    if (!_publicRoutes.contains(loc)) return AppRoutes.welcome;
    return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  debugPrint('[ROUTER] appRouterProvider.build() — GoRouter being CREATED (should happen once)');
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    // كل صفحة مغلّفة بـ RefreshablePage حتى يعيد زر "تحديث" العام تحميلها.
    routes: refreshableRoutes([
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerAcademy,
        builder: (context, state) => const AcademyRegistrationWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerLogin,
        builder: (context, state) => const PlayerLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerJoinRequest,
        builder: (context, state) => const PlayerJoinRequestWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.branches,
        builder: (context, state) => const BranchesScreen(),
      ),
      // ملاحظة: مسارات /player/chat و /player/notifications قبل /player
      GoRoute(
        path: AppRoutes.playerPendingApproval,
        builder: (context, state) => const PlayerPendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerChat,
        builder: (context, state) => const PlayerChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerNotifications,
        builder: (context, state) => const PlayerNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerAlbum,
        builder: (context, state) => const PlayerAlbumScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerMyVideos,
        builder: (context, state) => const MyVideosScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerStore,
        builder: (context, state) => const PlayerStoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerTeamKit,
        builder: (context, state) => const PlayerTeamKitScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerOffers,
        builder: (context, state) => const PlayerOffersScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerTournaments,
        builder: (context, state) => const PlayerTournamentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerDashboard,
        builder: (context, state) => const PlayerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyChat,
        builder: (context, state) => const AcademyConversationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyAlbum,
        builder: (context, state) => const AcademyAlbumScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyStore,
        builder: (context, state) => const StoreManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyTeamKit,
        builder: (context, state) => const KitManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyOffers,
        builder: (context, state) => const OffersManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.renewalRequests,
        builder: (context, state) => const RenewalRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.publicPlayerProfile,
        builder: (context, state) =>
            PublicPlayerProfileScreen(token: state.pathParameters['token']!),
      ),
      GoRoute(
        path: AppRoutes.families,
        builder: (context, state) => const FamiliesScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyList,
        builder: (context, state) => const AcademyListScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AcademyDetailScreen(academyId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.academyUsers,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return UsersListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.playersList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return PlayersListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.joinRequests,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return JoinRequestsListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.joinRequestDetail,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          final requestId = state.pathParameters['requestId']!;
          return JoinRequestDetailScreen(academyId: academyId, requestId: requestId);
        },
      ),
      GoRoute(
        path: AppRoutes.playerBirthdays,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return PlayerBirthdaysScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.groupsList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return GroupsListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.matchesList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return MatchesListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.tournamentsList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return TournamentsListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.subscriptionsList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return SubscriptionsListScreen(
            academyId: academyId,
            initialFilter: state.uri.queryParameters['filter'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.playerDetail,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          final playerId = state.pathParameters['playerId']!;
          return PlayerDetailScreen(playerId: playerId, academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.playerSubscriptions,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          final playerId = state.pathParameters['playerId']!;
          final playerName =
              state.uri.queryParameters['playerName'] ?? '';
          return PlayerSubscriptionHistoryScreen(
            playerId: playerId,
            academyId: academyId,
            playerName: playerName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.playerEvaluations,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          final playerId = state.pathParameters['playerId']!;
          final playerName =
              state.uri.queryParameters['playerName'] ?? '';
          return EvaluationHistoryScreen(
            playerId: playerId,
            academyId: academyId,
            playerName: playerName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.playerVideos,
        builder: (context, state) {
          final playerId = state.pathParameters['playerId']!;
          final playerName = state.uri.queryParameters['playerName'] ?? '';
          return PlayerVideosScreen(playerId: playerId, playerName: playerName);
        },
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return StaffListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.payrollList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return PayrollListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.expensesList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return ExpensesListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountSettings,
        builder: (context, state) => const AccountSettingsScreen(),
      ),
    ]),
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
