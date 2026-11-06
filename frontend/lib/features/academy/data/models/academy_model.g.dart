// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcademyModel _$AcademyModelFromJson(Map<String, dynamic> json) => AcademyModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      phone: json['phone'] as String,
      address: json['address'] as String,
      currency: json['currency'] as String? ?? 'EGP',
      sports: (json['sports'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      playerCount: (json['player_count'] as num?)?.toInt(),
      websiteUrl: json['websiteUrl'] as String? ?? '',
      facebookUrl: json['facebookUrl'] as String? ?? '',
      tiktokUrl: json['tiktokUrl'] as String? ?? '',
      instagramUrl: json['instagramUrl'] as String? ?? '',
    );

Map<String, dynamic> _$AcademyModelToJson(AcademyModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'logo_url': instance.logoUrl,
      'phone': instance.phone,
      'address': instance.address,
      'currency': instance.currency,
      'sports': instance.sports,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'player_count': instance.playerCount,
      'websiteUrl': instance.websiteUrl,
      'facebookUrl': instance.facebookUrl,
      'tiktokUrl': instance.tiktokUrl,
      'instagramUrl': instance.instagramUrl,
    };
