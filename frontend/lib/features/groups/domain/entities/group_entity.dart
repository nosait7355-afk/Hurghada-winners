import 'package:equatable/equatable.dart';

class GroupEntity extends Equatable {
  final String id;
  final String academyId;
  final String? sportId;
  final String name;
  final String? ageGroup;
  final int? capacity;
  final bool isActive;
  final int playersCount;
  final int? occupationRate;
  final int order;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GroupEntity({
    required this.id,
    required this.academyId,
    this.sportId,
    required this.name,
    this.ageGroup,
    this.capacity,
    this.isActive = true,
    this.playersCount = 0,
    this.occupationRate,
    this.order = 0,
    required this.createdAt,
    this.updatedAt,
  });

  GroupEntity copyWith({int? order, int? playersCount}) => GroupEntity(
        id: id,
        academyId: academyId,
        sportId: sportId,
        name: name,
        ageGroup: ageGroup,
        capacity: capacity,
        isActive: isActive,
        playersCount: playersCount ?? this.playersCount,
        occupationRate: occupationRate,
        order: order ?? this.order,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// المقاعد المتبقية (السعة − اللاعبون الحاليون)، أو null إذا لا سعة محددة.
  int? get remainingSeats =>
      capacity == null ? null : (capacity! - playersCount).clamp(0, capacity!);

  /// المجموعة ممتلئة عند بلوغ السعة القصوى.
  bool get isFull => capacity != null && playersCount >= capacity!;

  @override
  List<Object?> get props => [
        id,
        academyId,
        sportId,
        name,
        ageGroup,
        capacity,
        isActive,
        playersCount,
        occupationRate,
        order,
        createdAt,
        updatedAt,
      ];
}
