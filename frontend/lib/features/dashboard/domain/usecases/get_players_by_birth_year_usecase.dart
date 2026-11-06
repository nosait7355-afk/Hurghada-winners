import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:hurghada_winners/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetPlayersByBirthYearParams {
  final String? academyId;
  const GetPlayersByBirthYearParams({this.academyId});
}

class GetPlayersByBirthYearUsecase extends UseCase<List<PlayersByBirthYearEntity>, GetPlayersByBirthYearParams> {
  final DashboardRepository _repository;

  GetPlayersByBirthYearUsecase(this._repository);

  @override
  Future<Either<Failure, List<PlayersByBirthYearEntity>>> call(GetPlayersByBirthYearParams params) {
    return _repository.getPlayersByBirthYear(academyId: params.academyId);
  }
}
