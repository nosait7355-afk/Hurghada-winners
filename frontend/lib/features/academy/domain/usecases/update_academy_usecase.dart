import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/academy/domain/entities/academy_entity.dart';
import 'package:hurghada_winners/features/academy/domain/repositories/academy_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateAcademyParams {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String currency;
  final List<String> sports;
  final String? logoUrl;
  final String? websiteUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? instagramUrl;

  const UpdateAcademyParams({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.currency = 'EGP',
    this.sports = const [],
    this.logoUrl,
    this.websiteUrl,
    this.facebookUrl,
    this.tiktokUrl,
    this.instagramUrl,
  });
}

class UpdateAcademyUsecase extends UseCase<AcademyEntity, UpdateAcademyParams> {
  final AcademyRepository _repository;
  UpdateAcademyUsecase(this._repository);

  @override
  Future<Either<Failure, AcademyEntity>> call(UpdateAcademyParams params) {
    return _repository.updateAcademy(
      id: params.id,
      name: params.name,
      phone: params.phone,
      address: params.address,
      currency: params.currency,
      sports: params.sports,
      logoUrl: params.logoUrl,
      websiteUrl: params.websiteUrl,
      facebookUrl: params.facebookUrl,
      tiktokUrl: params.tiktokUrl,
      instagramUrl: params.instagramUrl,
    );
  }
}
