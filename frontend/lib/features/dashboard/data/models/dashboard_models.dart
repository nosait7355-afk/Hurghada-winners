import 'package:hurghada_winners/features/dashboard/domain/entities/dashboard_entity.dart';

class DashboardStatsModel {
  final int totalPlayers;
  final int activePlayers;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final double totalRevenue;
  final double currentMonthRevenue;
  final int newSubscriptionsCount;
  final int renewalsCount;
  final double averageEvaluationScore;
  final int totalGroups;
  final int activeGroups;
  final int playersWithoutGroup;
  final int largestGroupSize;
  final int groupOccupancyRate;
  final double avgPlayersPerGroup;

  const DashboardStatsModel({
    required this.totalPlayers,
    required this.activePlayers,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.totalRevenue,
    required this.currentMonthRevenue,
    required this.newSubscriptionsCount,
    required this.renewalsCount,
    required this.averageEvaluationScore,
    this.totalGroups = 0,
    this.activeGroups = 0,
    this.playersWithoutGroup = 0,
    this.largestGroupSize = 0,
    this.groupOccupancyRate = 0,
    this.avgPlayersPerGroup = 0,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalPlayers: (json['totalPlayers'] as num?)?.toInt() ?? 0,
      activePlayers: (json['activePlayers'] as num?)?.toInt() ?? 0,
      activeSubscriptions: (json['activeSubscriptions'] as num?)?.toInt() ?? 0,
      expiredSubscriptions: (json['expiredSubscriptions'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      currentMonthRevenue: (json['currentMonthRevenue'] as num?)?.toDouble() ?? 0.0,
      newSubscriptionsCount: (json['newSubscriptionsCount'] as num?)?.toInt() ?? 0,
      renewalsCount: (json['renewalsCount'] as num?)?.toInt() ?? 0,
      averageEvaluationScore: (json['averageEvaluationScore'] as num?)?.toDouble() ?? 0.0,
      totalGroups: (json['totalGroups'] as num?)?.toInt() ?? 0,
      activeGroups: (json['activeGroups'] as num?)?.toInt() ?? 0,
      playersWithoutGroup: (json['playersWithoutGroup'] as num?)?.toInt() ?? 0,
      largestGroupSize: (json['largestGroupSize'] as num?)?.toInt() ?? 0,
      groupOccupancyRate: (json['groupOccupancyRate'] as num?)?.toInt() ?? 0,
      avgPlayersPerGroup: (json['avgPlayersPerGroup'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DashboardStatsEntity toEntity() {
    return DashboardStatsEntity(
      totalPlayers: totalPlayers,
      activePlayers: activePlayers,
      activeSubscriptions: activeSubscriptions,
      expiredSubscriptions: expiredSubscriptions,
      totalRevenue: totalRevenue,
      currentMonthRevenue: currentMonthRevenue,
      newSubscriptionsCount: newSubscriptionsCount,
      renewalsCount: renewalsCount,
      averageEvaluationScore: averageEvaluationScore,
      totalGroups: totalGroups,
      activeGroups: activeGroups,
      playersWithoutGroup: playersWithoutGroup,
      largestGroupSize: largestGroupSize,
      groupOccupancyRate: groupOccupancyRate,
      avgPlayersPerGroup: avgPlayersPerGroup,
    );
  }
}

class RevenueByMonthModel {
  final String month;
  final double revenue;
  final int count;

  const RevenueByMonthModel({
    required this.month,
    required this.revenue,
    required this.count,
  });

  factory RevenueByMonthModel.fromJson(Map<String, dynamic> json) {
    return RevenueByMonthModel(
      month: (json['month'] as String?) ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  RevenueByMonthEntity toEntity() {
    return RevenueByMonthEntity(
      month: month,
      revenue: revenue,
      count: count,
    );
  }
}

class SubscriptionsByTypeModel {
  final int newSubscription;
  final int renewal;
  final int total;

  const SubscriptionsByTypeModel({
    required this.newSubscription,
    required this.renewal,
    required this.total,
  });

  factory SubscriptionsByTypeModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionsByTypeModel(
      newSubscription: (json['newSubscription'] as num?)?.toInt() ?? 0,
      renewal: (json['renewal'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  SubscriptionsByTypeEntity toEntity() {
    return SubscriptionsByTypeEntity(
      newSubscription: newSubscription,
      renewal: renewal,
      total: total,
    );
  }
}

class PlayersByBirthYearModel {
  final int year;
  final int count;

  const PlayersByBirthYearModel({
    required this.year,
    required this.count,
  });

  factory PlayersByBirthYearModel.fromJson(Map<String, dynamic> json) {
    return PlayersByBirthYearModel(
      year: (json['year'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  PlayersByBirthYearEntity toEntity() {
    return PlayersByBirthYearEntity(year: year, count: count);
  }
}

class EvaluationDistributionModel {
  final int excellent;
  final int good;
  final int needsImprovement;
  final int total;

  const EvaluationDistributionModel({
    required this.excellent,
    required this.good,
    required this.needsImprovement,
    required this.total,
  });

  factory EvaluationDistributionModel.fromJson(Map<String, dynamic> json) {
    return EvaluationDistributionModel(
      excellent: (json['excellent'] as num?)?.toInt() ?? 0,
      good: (json['good'] as num?)?.toInt() ?? 0,
      needsImprovement: (json['needsImprovement'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  EvaluationDistributionEntity toEntity() {
    return EvaluationDistributionEntity(
      excellent: excellent,
      good: good,
      needsImprovement: needsImprovement,
      total: total,
    );
  }
}

class RecentActivityModel {
  final String userName;
  final String actionType;
  final String entityType;
  final String entityName;
  final DateTime createdAt;

  const RecentActivityModel({
    required this.userName,
    required this.actionType,
    required this.entityType,
    required this.entityName,
    required this.createdAt,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      userName: (json['userName'] as String?) ?? '',
      actionType: (json['actionType'] as String?) ?? '',
      entityType: (json['entityType'] as String?) ?? '',
      entityName: (json['entityName'] as String?) ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  RecentActivityEntity toEntity() {
    return RecentActivityEntity(
      userName: userName,
      actionType: actionType,
      entityType: entityType,
      entityName: entityName,
      createdAt: createdAt,
    );
  }
}

class RecentActivitiesModel {
  final List<RecentActivityModel> activities;

  const RecentActivitiesModel({required this.activities});

  /// الـ backend يُرجع قائمة مسطّحة من سجل النشاط (الأحدث أولاً).
  factory RecentActivitiesModel.fromList(List<dynamic> raw) {
    return RecentActivitiesModel(
      activities: raw
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  RecentActivitiesEntity toEntity() {
    return RecentActivitiesEntity(
      activities: activities.map((m) => m.toEntity()).toList(),
    );
  }
}
