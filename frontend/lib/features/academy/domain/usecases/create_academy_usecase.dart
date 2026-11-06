import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/academy/domain/entities/academy_entity.dart';
import 'package:hurghada_winners/features/academy/domain/repositories/academy_repository.dart';
import 'package:dartz/dartz.dart';

class CreateAcademyParams {
  final String name;
  final String phone;
  final String address;
  final String currency;
  final List<String> sports;
  final String? logoUrl;

  const CreateAcademyParams({
    required this.name,
    required this.phone,
    required this.address,
    this.currency = 'EGP',
    this.sports = const [],
    this.logoUrl,
  });
}

class CreateAcademyUsecase extends UseCase<AcademyEntity, CreateAcademyParams> {
  final AcademyRepository _repository;
  CreateAcademyUsecase(this._repository);

  @override
  Future<Either<Failure, AcademyEntity>> call(CreateAcademyParams params) {
    return _repository.createAcademy(
      name: params.name,
      phone: params.phone,
      address: params.address,
      currency: params.currency,
      sports: params.sports,
      logoUrl: params.logoUrl,
    );
  }
}
