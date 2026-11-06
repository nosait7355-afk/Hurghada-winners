import 'package:hurghada_winners/features/academy/domain/entities/academy_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'academy_model.g.dart';

@JsonSerializable()
class AcademyModel {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  final String phone;
  final String address;
  @JsonKey(defaultValue: 'EGP')
  final String currency;
  @JsonKey(defaultValue: <String>[])
  final List<String> sports;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'player_count')
  final int? playerCount;
  @JsonKey(defaultValue: '')
  final String? websiteUrl;
  @JsonKey(defaultValue: '')
  final String? facebookUrl;
  @JsonKey(defaultValue: '')
  final String? tiktokUrl;
  @JsonKey(defaultValue: '')
  final String? instagramUrl;

  const AcademyModel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.phone,
    required this.address,
    this.currency = 'EGP',
    this.sports = const [],
    required this.createdAt,
    this.updatedAt,
    this.playerCount,
    this.websiteUrl,
    this.facebookUrl,
    this.tiktokUrl,
    this.instagramUrl,
  });

  factory AcademyModel.fromJson(Map<String, dynamic> json) =>
      _$AcademyModelFromJson(json);

  Map<String, dynamic> toJson() => _$AcademyModelToJson(this);

  AcademyEntity toEntity() => AcademyEntity(
        id: id,
        name: name,
        logoUrl: logoUrl,
        phone: phone,
        address: address,
        currency: currency,
        sports: sports,
        createdAt: createdAt,
        updatedAt: updatedAt,
        playerCount: playerCount,
        websiteUrl: websiteUrl,
        facebookUrl: facebookUrl,
        tiktokUrl: tiktokUrl,
        instagramUrl: instagramUrl,
      );
}
