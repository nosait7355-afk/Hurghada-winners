import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/academy/domain/entities/academy_entity.dart';
import 'package:dartz/dartz.dart';

abstract class AcademyRepository {
  Future<Either<Failure, List<AcademyEntity>>> getAcademies();
  Future<Either<Failure, AcademyEntity>> getAcademyById(String id);
  Future<Either<Failure, AcademyEntity>> createAcademy({
    required String name,
    required String phone,
    required String address,
    String currency,
    List<String> sports,
    String? logoUrl,
  });
  Future<Either<Failure, AcademyEntity>> updateAcademy({
    required String id,
    required String name,
    required String phone,
    required String address,
    String currency,
    List<String> sports,
    String? logoUrl,
    String? websiteUrl,
    String? facebookUrl,
    String? tiktokUrl,
    String? instagramUrl,
  });
  Future<Either<Failure, void>> deleteAcademy(String id);
}
