import 'package:equatable/equatable.dart';

enum SubscriptionType { newSubscription, renewal }

enum SubscriptionStatus { active, expired }

class SubscriptionEntity extends Equatable {
  final String id;
  final String academyId;
  final String playerId;
  /// اسم اللاعب — مُستخرَج من populate الـ backend
  final String playerName;
  final String playerCode;
  final String? playerPhone;
  final String? playerImageUrl;
  final SubscriptionType type;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SubscriptionEntity({
    required this.id,
    required this.academyId,
    required this.playerId,
    this.playerName = '',
    this.playerCode = '',
    this.playerPhone,
    this.playerImageUrl,
    required this.type,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  SubscriptionStatus get status =>
      DateTime.now().isBefore(endDate) ||
              DateTime.now().isAtSameMomentAs(endDate)
          ? SubscriptionStatus.active
          : SubscriptionStatus.expired;

  bool get isActive => status == SubscriptionStatus.active;

  String get typeLabel =>
      type == SubscriptionType.newSubscription ? 'اشتراك جديد' : 'تجديد';

  String get statusLabel => isActive ? 'نشط' : 'منتهي';

  /// أيام متبقية حتى انتهاء الاشتراك (سالب إذا كان منتهياً)
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  bool get isExpiringSoon => isActive && daysRemaining <= 7;

  /// نشط | ينتهي قريباً | منتهي — لا يوجد مفهوم "مجمد" في الـ backend حالياً
  String get displayStatus {
    if (!isActive) return 'منتهي';
    if (isExpiringSoon) return 'ينتهي قريباً';
    return 'نشط';
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        playerId,
        playerName,
        playerCode,
        playerPhone,
        playerImageUrl,
        type,
        amount,
        startDate,
        endDate,
        notes,
        createdAt,
        updatedAt,
      ];
}
