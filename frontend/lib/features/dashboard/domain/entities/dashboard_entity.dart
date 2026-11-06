import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  final int totalPlayers;
  final int activePlayers;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final double totalRevenue;
  final double currentMonthRevenue;
  final int newSubscriptionsCount;
  final int renewalsCount;
  final double averageEvaluationScore;
  // إحصاءات المجموعات
  final int totalGroups;
  final int activeGroups;
  final int playersWithoutGroup;
  final int largestGroupSize;
  final int groupOccupancyRate;
  final double avgPlayersPerGroup;

  const DashboardStatsEntity({
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

  @override
  List<Object?> get props => [
        totalPlayers,
        activePlayers,
        activeSubscriptions,
        expiredSubscriptions,
        totalRevenue,
        currentMonthRevenue,
        newSubscriptionsCount,
        renewalsCount,
        averageEvaluationScore,
        totalGroups,
        activeGroups,
        playersWithoutGroup,
        largestGroupSize,
        groupOccupancyRate,
        avgPlayersPerGroup,
      ];
}

class RevenueByMonthEntity extends Equatable {
  final String month; // "2024-01"
  final double revenue;
  final int count;

  const RevenueByMonthEntity({
    required this.month,
    required this.revenue,
    required this.count,
  });

  @override
  List<Object?> get props => [month, revenue, count];
}

class SubscriptionsByTypeEntity extends Equatable {
  final int newSubscription;
  final int renewal;
  final int total;

  const SubscriptionsByTypeEntity({
    required this.newSubscription,
    required this.renewal,
    required this.total,
  });

  @override
  List<Object?> get props => [newSubscription, renewal, total];
}

class PlayersByBirthYearEntity extends Equatable {
  final int year;
  final int count;

  const PlayersByBirthYearEntity({
    required this.year,
    required this.count,
  });

  @override
  List<Object?> get props => [year, count];
}

class EvaluationDistributionEntity extends Equatable {
  final int excellent;
  final int good;
  final int needsImprovement;
  final int total;

  const EvaluationDistributionEntity({
    required this.excellent,
    required this.good,
    required this.needsImprovement,
    required this.total,
  });

  @override
  List<Object?> get props => [excellent, good, needsImprovement, total];
}

/// نشاط واحد من سجل النشاط الحقيقي (من قام بالإجراء).
class RecentActivityEntity extends Equatable {
  final String userName;
  final String actionType; // CREATE_PLAYER, RENEW_SUBSCRIPTION, ...
  final String entityType; // PLAYER, SUBSCRIPTION, EVALUATION, ATTENDANCE, USER, ACADEMY
  final String entityName;
  final DateTime createdAt;

  const RecentActivityEntity({
    required this.userName,
    required this.actionType,
    required this.entityType,
    required this.entityName,
    required this.createdAt,
  });

  /// الجملة المعروضة: «{المستخدم} {فعل} {اسم العنصر}».
  String get sentence {
    final who = userName.trim().isNotEmpty ? userName : 'مستخدم';
    final verb = switch (actionType) {
      'CREATE_PLAYER' => 'قام بإضافة اللاعب',
      'UPDATE_PLAYER' => 'قام بتعديل بيانات اللاعب',
      'DELETE_PLAYER' => 'قام بحذف اللاعب',
      'ADD_SUBSCRIPTION' => 'قام بإضافة اشتراك للاعب',
      'RENEW_SUBSCRIPTION' => 'قام بتجديد اشتراك اللاعب',
      'DELETE_SUBSCRIPTION' => 'قام بحذف اشتراك اللاعب',
      'ADD_EVALUATION' => 'قام بإضافة تقييم للاعب',
      'UPDATE_EVALUATION' => 'قام بتعديل تقييم اللاعب',
      'DELETE_EVALUATION' => 'قام بحذف تقييم اللاعب',
      'RECORD_ATTENDANCE' => 'قام بتسجيل حضور اللاعب',
      'ADD_USER' => 'قام بإضافة المستخدم',
      'UPDATE_USER' => 'قام بتعديل المستخدم',
      'DELETE_USER' => 'قام بحذف المستخدم',
      'UPDATE_ACADEMY' => 'قام بتعديل بيانات الأكاديمية',
      'CREATE_PLAYER_ACCOUNT' => 'قام بإنشاء حساب دخول للاعب',
      'CHANGE_PLAYER_PASSWORD' => 'قام بتغيير كلمة مرور حساب اللاعب',
      'RESET_PLAYER_PASSWORD' => 'قام بإعادة إنشاء كلمة مرور حساب اللاعب',
      'ENABLE_PLAYER_ACCOUNT' => 'قام بتفعيل حساب اللاعب',
      'DISABLE_PLAYER_ACCOUNT' => 'قام بتعطيل حساب اللاعب',
      'CREATE_GROUP' => 'قام بإنشاء المجموعة',
      'UPDATE_GROUP' => 'قام بتعديل المجموعة',
      'DELETE_GROUP' => 'قام بحذف المجموعة',
      _ => 'قام بإجراء',
    };
    return entityName.trim().isNotEmpty ? '$who $verb $entityName' : '$who $verb';
  }

  @override
  List<Object?> get props =>
      [userName, actionType, entityType, entityName, createdAt];
}

class RecentActivitiesEntity extends Equatable {
  final List<RecentActivityEntity> activities;

  const RecentActivitiesEntity({required this.activities});

  /// الأحدث أولاً (الـ backend يُرتّب بالفعل، ونحافظ على الترتيب).
  List<RecentActivityEntity> get all => activities;

  @override
  List<Object?> get props => [activities];
}
