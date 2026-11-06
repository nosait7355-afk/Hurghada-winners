import 'package:equatable/equatable.dart';

class AcademyEntity extends Equatable {
  final String id;
  final String name;
  final String? logoUrl;
  final String phone;
  final String address;
  final String currency;
  final List<String> sports;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? playerCount;
  final String? websiteUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? instagramUrl;

  const AcademyEntity({
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

  /// True when the academy runs more than one sport — controls whether
  /// sport sections / filters / selectors are shown across the UI.
  bool get isMultiSport => sports.length > 1;

  @override
  List<Object?> get props => [id, name, logoUrl, phone, address, currency, sports, createdAt, updatedAt, playerCount, websiteUrl, facebookUrl, tiktokUrl, instagramUrl];
}
