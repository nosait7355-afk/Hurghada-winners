import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_model.g.dart';

@JsonSerializable()
class GroupModel {
  @JsonKey(name: '_id')
  final String id;
  final String academyId;
  final String? sportId;
  final String name;
  final String? ageGroup;
  final int? capacity;
  @JsonKey(defaultValue: true)
  final bool isActive;
  @JsonKey(defaultValue: 0)
  final int playersCount;
  final int? occupationRate;
  @JsonKey(defaultValue: 0)
  final int order;
  // الخادم يُرسل الطوابع الزمنية بصيغة snake_case (created_at / updated_at).
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const GroupModel({
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

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupModelToJson(this);

  GroupEntity toEntity() => GroupEntity(
        id: id,
        academyId: academyId,
        sportId: sportId,
        name: name,
        ageGroup: ageGroup,
        capacity: capacity,
        isActive: isActive,
        playersCount: playersCount,
        occupationRate: occupationRate,
        order: order,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
