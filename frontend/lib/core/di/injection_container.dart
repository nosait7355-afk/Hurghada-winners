import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:hurghada_winners/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:hurghada_winners/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_evaluation_distribution_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_players_by_birth_year_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_recent_activities_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_revenue_by_month_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_subscriptions_by_type_usecase.dart';
import 'package:hurghada_winners/core/network/token_manager.dart';
import 'package:hurghada_winners/features/evaluation/data/datasources/evaluation_remote_datasource.dart';
import 'package:hurghada_winners/features/evaluation/data/repositories/evaluation_repository_impl.dart';
import 'package:hurghada_winners/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/create_evaluation_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/delete_evaluation_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/get_evaluation_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/get_evaluations_by_academy_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/get_evaluations_by_player_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/get_latest_evaluation_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/update_evaluation_usecase.dart';
import 'package:hurghada_winners/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:hurghada_winners/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:hurghada_winners/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/get_revenue_summary_usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/get_subscriptions_by_academy_usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/get_subscriptions_by_player_usecase.dart';
import 'package:hurghada_winners/features/subscription/domain/usecases/update_subscription_notes_usecase.dart';
import 'package:hurghada_winners/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:hurghada_winners/features/academy/data/repositories/academy_repository_impl.dart';
import 'package:hurghada_winners/features/academy/domain/repositories/academy_repository.dart';
import 'package:hurghada_winners/features/academy/domain/usecases/create_academy_usecase.dart';
import 'package:hurghada_winners/features/academy/domain/usecases/delete_academy_usecase.dart';
import 'package:hurghada_winners/features/academy/domain/usecases/get_academies_usecase.dart';
import 'package:hurghada_winners/features/academy/domain/usecases/get_academy_usecase.dart';
import 'package:hurghada_winners/features/academy/domain/usecases/update_academy_usecase.dart';
import 'package:hurghada_winners/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:hurghada_winners/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hurghada_winners/features/auth/domain/repositories/auth_repository.dart';
import 'package:hurghada_winners/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:hurghada_winners/features/auth/domain/usecases/login_usecase.dart';
import 'package:hurghada_winners/features/auth/domain/usecases/logout_usecase.dart';
import 'package:hurghada_winners/features/player/data/datasources/player_remote_datasource.dart';
import 'package:hurghada_winners/features/player/data/player_account_service.dart';
import 'package:hurghada_winners/features/player/data/join_request_service.dart';
import 'package:hurghada_winners/features/notification/data/notification_alerts_service.dart';
import 'package:hurghada_winners/features/offers/data/offers_service.dart';
import 'package:hurghada_winners/features/groups/data/group_move_service.dart';
import 'package:hurghada_winners/features/player/data/repositories/player_repository_impl.dart';
import 'package:hurghada_winners/features/player/domain/repositories/player_repository.dart';
import 'package:hurghada_winners/features/player/domain/usecases/create_player_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/delete_player_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_player_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_players_birthdays_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_players_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/search_players_usecase.dart';
import 'package:hurghada_winners/features/player/domain/usecases/update_player_usecase.dart';
import 'package:hurghada_winners/features/groups/data/datasources/groups_remote_datasource.dart';
import 'package:hurghada_winners/features/groups/data/repositories/groups_repository_impl.dart';
import 'package:hurghada_winners/features/groups/domain/repositories/groups_repository.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/create_group_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/delete_group_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/get_group_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/get_groups_by_academy_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/get_groups_by_sport_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/get_groups_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/update_group_usecase.dart';
import 'package:hurghada_winners/features/user/data/datasources/user_remote_datasource.dart';
import 'package:hurghada_winners/features/user/data/repositories/user_repository_impl.dart';
import 'package:hurghada_winners/features/user/domain/repositories/user_repository.dart';
import 'package:hurghada_winners/features/user/domain/usecases/activate_user_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/create_user_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/deactivate_user_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/delete_user_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/reset_password_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/get_users_by_academy_usecase.dart';
import 'package:hurghada_winners/features/user/domain/usecases/update_user_usecase.dart';
import 'package:hurghada_winners/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:hurghada_winners/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hurghada_winners/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hurghada_winners/features/attendance/domain/usecases/delete_attendance_usecase.dart';
import 'package:hurghada_winners/features/attendance/domain/usecases/get_attendance_log_usecase.dart';
import 'package:hurghada_winners/features/attendance/domain/usecases/get_attendance_report_usecase.dart';
import 'package:hurghada_winners/features/attendance/domain/usecases/record_attendance_usecase.dart';
import 'package:hurghada_winners/features/staff/data/datasources/staff_remote_datasource.dart';
import 'package:hurghada_winners/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:hurghada_winners/features/staff/domain/repositories/staff_repository.dart';
import 'package:hurghada_winners/features/payroll/data/datasources/payroll_remote_datasource.dart';
import 'package:hurghada_winners/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hurghada_winners/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hurghada_winners/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:hurghada_winners/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:hurghada_winners/features/expenses/domain/repositories/expense_repository.dart';
import 'package:hurghada_winners/features/academy_registration/data/academy_registration_service.dart';
import 'package:hurghada_winners/features/player_portal/data/player_api_service.dart';
import 'package:hurghada_winners/features/chat/data/chat_api_service.dart';
import 'package:hurghada_winners/features/academy_album/data/academy_album_service.dart';
import 'package:hurghada_winners/features/store/data/store_service.dart';
import 'package:hurghada_winners/features/team_kit/data/team_kit_service.dart';
import 'package:hurghada_winners/core/auth/saved_accounts_store.dart';
import 'package:hurghada_winners/features/player/data/player_share_service.dart';
import 'package:hurghada_winners/features/family/data/family_service.dart';
import 'package:hurghada_winners/features/subscription/data/renewal_request_service.dart';
import 'package:hurghada_winners/features/matches/data/matches_service.dart';
import 'package:hurghada_winners/features/tournaments/data/tournaments_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  // Core
  sl.registerLazySingleton<TokenManager>(
    () => TokenManager(sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<SavedAccountsStore>(
    () => SavedAccountsStore(sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl<TokenManager>()),
  );

  // Auth
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: sl<AuthRemoteDatasource>(),
      tokenManager: sl<TokenManager>(),
    ),
  );
  sl.registerLazySingleton<LoginUsecase>(
    () => LoginUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUsecase>(
    () => LogoutUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentUserUsecase>(
    () => GetCurrentUserUsecase(sl<AuthRepository>()),
  );

  // Academy
  sl.registerLazySingleton<AcademyRemoteDatasource>(
    () => AcademyRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AcademyRepository>(
    () => AcademyRepositoryImpl(
      remoteDatasource: sl<AcademyRemoteDatasource>(),
    ),
  );
  sl.registerLazySingleton<GetAcademiesUsecase>(
    () => GetAcademiesUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<GetAcademyUsecase>(
    () => GetAcademyUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<CreateAcademyUsecase>(
    () => CreateAcademyUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<UpdateAcademyUsecase>(
    () => UpdateAcademyUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<DeleteAcademyUsecase>(
    () => DeleteAcademyUsecase(sl<AcademyRepository>()),
  );

  // User Management
  sl.registerLazySingleton<UserRemoteDatasource>(
    () => UserRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDatasource: sl<UserRemoteDatasource>(),
    ),
  );
  sl.registerLazySingleton<GetUsersByAcademyUsecase>(
    () => GetUsersByAcademyUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<CreateUserUsecase>(
    () => CreateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<UpdateUserUsecase>(
    () => UpdateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<DeleteUserUsecase>(
    () => DeleteUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<ActivateUserUsecase>(
    () => ActivateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<DeactivateUserUsecase>(
    () => DeactivateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<ResetPasswordUsecase>(
    () => ResetPasswordUsecase(sl<UserRepository>()),
  );

  // Player
  sl.registerLazySingleton<PlayerRemoteDatasource>(
    () => PlayerRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(remoteDatasource: sl<PlayerRemoteDatasource>()),
  );
  sl.registerLazySingleton<GetPlayersUsecase>(
    () => GetPlayersUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<SearchPlayersUsecase>(
    () => SearchPlayersUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<GetPlayersBirthdaysUsecase>(
    () => GetPlayersBirthdaysUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<GetPlayerUsecase>(
    () => GetPlayerUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<CreatePlayerUsecase>(
    () => CreatePlayerUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<UpdatePlayerUsecase>(
    () => UpdatePlayerUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<DeletePlayerUsecase>(
    () => DeletePlayerUsecase(sl<PlayerRepository>()),
  );

  // Groups
  sl.registerLazySingleton<GroupsRemoteDatasource>(
    () => GroupsRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<GroupsRepository>(
    () => GroupsRepositoryImpl(remoteDatasource: sl<GroupsRemoteDatasource>()),
  );
  sl.registerLazySingleton<GetGroupsUsecase>(
    () => GetGroupsUsecase(sl<GroupsRepository>()),
  );
  sl.registerLazySingleton<GetGroupsByAcademyUsecase>(
    () => GetGroupsByAcademyUsecase(sl<GroupsRepository>()),
  );
  sl.registerLazySingleton<GetGroupsBySportUsecase>(
    () => GetGroupsBySportUsecase(sl<GroupsRepository>()),
  );
  sl.registerLazySingleton<GetGroupUsecase>(
    () => GetGroupUsecase(sl<GroupsRepository>()),
  );
  sl.registerLazySingleton<CreateGroupUsecase>(
    () => CreateGroupUsecase(sl<GroupsRepository>()),
  );
  sl.registerLazySingleton<UpdateGroupUsecase>(
    () => UpdateGroupUsecase(sl<GroupsRepository>()),
  );
  sl.registerLazySingleton<DeleteGroupUsecase>(
    () => DeleteGroupUsecase(sl<GroupsRepository>()),
  );

  // Subscription
  sl.registerLazySingleton<SubscriptionRemoteDatasource>(
    () => SubscriptionRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(
        remoteDatasource: sl<SubscriptionRemoteDatasource>()),
  );
  sl.registerLazySingleton<GetSubscriptionsByPlayerUsecase>(
    () => GetSubscriptionsByPlayerUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<GetSubscriptionsByAcademyUsecase>(
    () => GetSubscriptionsByAcademyUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<GetSubscriptionUsecase>(
    () => GetSubscriptionUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<CreateSubscriptionUsecase>(
    () => CreateSubscriptionUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<UpdateSubscriptionNotesUsecase>(
    () => UpdateSubscriptionNotesUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<DeleteSubscriptionUsecase>(
    () => DeleteSubscriptionUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<GetRevenueSummaryUsecase>(
    () => GetRevenueSummaryUsecase(sl<SubscriptionRepository>()),
  );

  // Evaluation
  sl.registerLazySingleton<EvaluationRemoteDatasource>(
    () => EvaluationRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<EvaluationRepository>(
    () => EvaluationRepositoryImpl(
        remoteDatasource: sl<EvaluationRemoteDatasource>()),
  );
  sl.registerLazySingleton<GetEvaluationsByPlayerUsecase>(
    () => GetEvaluationsByPlayerUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<GetLatestEvaluationUsecase>(
    () => GetLatestEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<GetEvaluationUsecase>(
    () => GetEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<CreateEvaluationUsecase>(
    () => CreateEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<UpdateEvaluationUsecase>(
    () => UpdateEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<DeleteEvaluationUsecase>(
    () => DeleteEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<GetEvaluationsByAcademyUsecase>(
    () => GetEvaluationsByAcademyUsecase(sl<EvaluationRepository>()),
  );

  // Dashboard
  sl.registerLazySingleton<DashboardRemoteDatasource>(
    () => DashboardRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDatasource: sl<DashboardRemoteDatasource>()),
  );
  sl.registerLazySingleton<GetDashboardStatsUsecase>(
    () => GetDashboardStatsUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetRevenueByMonthUsecase>(
    () => GetRevenueByMonthUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetSubscriptionsByTypeUsecase>(
    () => GetSubscriptionsByTypeUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetPlayersByBirthYearUsecase>(
    () => GetPlayersByBirthYearUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetEvaluationDistributionUsecase>(
    () => GetEvaluationDistributionUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetRecentActivitiesUsecase>(
    () => GetRecentActivitiesUsecase(sl<DashboardRepository>()),
  );

  // Attendance
  sl.registerLazySingleton<AttendanceRemoteDatasource>(
    () => AttendanceRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
        remoteDatasource: sl<AttendanceRemoteDatasource>()),
  );
  sl.registerLazySingleton<RecordAttendanceUsecase>(
    () => RecordAttendanceUsecase(sl<AttendanceRepository>()),
  );
  sl.registerLazySingleton<GetAttendanceLogUsecase>(
    () => GetAttendanceLogUsecase(sl<AttendanceRepository>()),
  );
  sl.registerLazySingleton<GetAttendanceReportUsecase>(
    () => GetAttendanceReportUsecase(sl<AttendanceRepository>()),
  );
  sl.registerLazySingleton<DeleteAttendanceUsecase>(
    () => DeleteAttendanceUsecase(sl<AttendanceRepository>()),
  );

  // Staff
  sl.registerLazySingleton<StaffRemoteDatasource>(
    () => StaffRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(remoteDatasource: sl<StaffRemoteDatasource>()),
  );

  // Payroll
  sl.registerLazySingleton<PayrollRemoteDatasource>(
    () => PayrollRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<PayrollRepository>(
    () => PayrollRepositoryImpl(remoteDatasource: sl<PayrollRemoteDatasource>()),
  );

  // Expenses
  sl.registerLazySingleton<ExpenseRemoteDatasource>(
    () => ExpenseRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(remoteDatasource: sl<ExpenseRemoteDatasource>()),
  );

  // ── منصة Nosait SaaS ──
  sl.registerLazySingleton<AcademyRegistrationService>(
    () => AcademyRegistrationService(sl<ApiClient>(), sl<TokenManager>()),
  );
  sl.registerLazySingleton<PlayerApiService>(
    () => PlayerApiService(sl<ApiClient>(), sl<TokenManager>()),
  );
  sl.registerLazySingleton<ChatApiService>(
    () => ChatApiService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AcademyAlbumService>(
    () => AcademyAlbumService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<StoreService>(
    () => StoreService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<TeamKitService>(
    () => TeamKitService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<RenewalRequestService>(
    () => RenewalRequestService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<PlayerShareService>(
    () => PlayerShareService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<FamilyService>(
    () => FamilyService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<MatchesService>(
    () => MatchesService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<TournamentsService>(
    () => TournamentsService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<PlayerAccountService>(
    () => PlayerAccountService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<JoinRequestService>(
    () => JoinRequestService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<NotificationAlertsService>(
    () => NotificationAlertsService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<OffersService>(
    () => OffersService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<GroupMoveService>(
    () => GroupMoveService(sl<ApiClient>()),
  );
}
