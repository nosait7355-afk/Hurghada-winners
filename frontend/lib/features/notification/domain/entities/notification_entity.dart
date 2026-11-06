import 'package:equatable/equatable.dart';

enum NotificationType {
  birthday,
  subscriptionExpiring,
  subscriptionExpired,
  joinRequest,
  /// غياب متكرر (تمرينتان متتاليتان أو أكثر).
  absence,
  system,
}

class NotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? playerId;
  // بيانات لازمة لفتح WhatsApp مباشرةً عند الضغط على الإشعار.
  final String? parentPhone;
  final String? playerName;
  final String? academyName;

  /// الأكاديمية التي ينتمي إليها الإشعار. لازمة للسوبر أدمن تحديداً: إشعاراته
  /// تجمع كل الفروع، فلا يمكن اشتقاق الفرع من أكاديمية المستخدم (وهي null له).
  final String? academyId;

  /// تاريخ انتهاء الاشتراك (= موعد التجديد) لإشعارات الاشتراك — يدخل في رسالة
  /// التذكير الجاهزة.
  final DateTime? subscriptionEndDate;

  /// عدد التمرينات المتتالية الغائبة (لتنبيه الغياب).
  final int? absentCount;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.playerId,
    this.parentPhone,
    this.playerName,
    this.academyName,
    this.academyId,
    this.subscriptionEndDate,
    this.absentCount,
  });

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        playerId: playerId,
        parentPhone: parentPhone,
        playerName: playerName,
        academyName: academyName,
        academyId: academyId,
        subscriptionEndDate: subscriptionEndDate,
        absentCount: absentCount,
      );

  @override
  List<Object?> get props =>
      [id, type, title, body, createdAt, isRead, playerId, parentPhone, playerName, academyName, academyId, subscriptionEndDate, absentCount];
}
