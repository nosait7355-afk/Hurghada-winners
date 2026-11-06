import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_evaluation_distribution_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_players_by_birth_year_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_recent_activities_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_revenue_by_month_usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/usecases/get_subscriptions_by_type_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardState {
  final DashboardStatsEntity? stats;
  final List<RevenueByMonthEntity> revenueByMonth;
  final SubscriptionsByTypeEntity? subscriptionsByType;
  final List<PlayersByBirthYearEntity> playersByBirthYear;
  final EvaluationDistributionEntity? evaluationDistribution;
  final RecentActivitiesEntity? recentActivities;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.stats,
    required this.revenueByMonth,
    this.subscriptionsByType,
    required this.playersByBirthYear,
    this.evaluationDistribution,
    this.recentActivities,
    required this.isLoading,
    this.error,
  });

  static const DashboardState empty = DashboardState(
    revenueByMonth: [],
    playersByBirthYear: [],
    isLoading: false,
  );

  DashboardState copyWith({
    DashboardStatsEntity? stats,
    List<RevenueByMonthEntity>? revenueByMonth,
    SubscriptionsByTypeEntity? subscriptionsByType,
    List<PlayersByBirthYearEntity>? playersByBirthYear,
    EvaluationDistributionEntity? evaluationDistribution,
    RecentActivitiesEntity? recentActivities,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      revenueByMonth: revenueByMonth ?? this.revenueByMonth,
      subscriptionsByType: subscriptionsByType ?? this.subscriptionsByType,
      playersByBirthYear: playersByBirthYear ?? this.playersByBirthYear,
      evaluationDistribution: evaluationDistribution ?? this.evaluationDistribution,
      recentActivities: recentActivities ?? this.recentActivities,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    return DashboardState.empty;
  }

  Future<DashboardState> _loadAll({String? academyId}) async {
    debugPrint('[DASHBOARD] _loadAll() → starting 6 parallel API calls academyId=$academyId');
    final stopwatch = Stopwatch()..start();
    final results = await Future.wait([
      sl<GetDashboardStatsUsecase>()(GetDashboardStatsParams(academyId: academyId)),
      sl<GetRevenueByMonthUsecase>()(GetRevenueByMonthParams(academyId: academyId)),
      sl<GetSubscriptionsByTypeUsecase>()(GetSubscriptionsByTypeParams(academyId: academyId)),
      sl<GetPlayersByBirthYearUsecase>()(GetPlayersByBirthYearParams(academyId: academyId)),
      sl<GetEvaluationDistributionUsecase>()(GetEvaluationDistributionParams(academyId: academyId)),
      sl<GetRecentActivitiesUsecase>()(GetRecentActivitiesParams(academyId: academyId)),
    ]);
    stopwatch.stop();
    debugPrint('[DASHBOARD] _loadAll() → all 6 calls done in ${stopwatch.elapsedMilliseconds}ms');

    final statsResult = results[0] as Either;
    final revenueResult = results[1] as Either;
    final subsTypeResult = results[2] as Either;
    final playersBirthResult = results[3] as Either;
    final evalDistResult = results[4] as Either;
    final recentActResult = results[5] as Either;

    return DashboardState(
      stats: statsResult.fold((_) => null, (v) => v as DashboardStatsEntity),
      revenueByMonth: revenueResult.fold((_) => <RevenueByMonthEntity>[], (v) => v as List<RevenueByMonthEntity>),
      subscriptionsByType: subsTypeResult.fold((_) => null, (v) => v as SubscriptionsByTypeEntity),
      playersByBirthYear: playersBirthResult.fold((_) => <PlayersByBirthYearEntity>[], (v) => v as List<PlayersByBirthYearEntity>),
      evaluationDistribution: evalDistResult.fold((_) => null, (v) => v as EvaluationDistributionEntity),
      recentActivities: recentActResult.fold((_) => null, (v) => v as RecentActivitiesEntity),
      isLoading: false,
    );
  }

  Future<void> refresh({String? academyId}) async {
    debugPrint('[DASHBOARD] refresh() → academyId=$academyId');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadAll(academyId: academyId));
    debugPrint('[DASHBOARD] refresh() → done, isLoading=${state.isLoading} hasError=${state.hasError}');
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
