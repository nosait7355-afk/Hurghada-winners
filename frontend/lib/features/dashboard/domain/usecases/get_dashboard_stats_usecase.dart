import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:hurghada_winners/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetDashboardStatsParams {
  final String? academyId;
  const GetDashboardStatsParams({this.academyId});
}

class GetDashboardStatsUsecase extends UseCase<DashboardStatsEntity, GetDashboardStatsParams> {
  final DashboardRepository _repository;

  GetDashboardStatsUsecase(this._repository);

  @override
  Future<Either<Failure, DashboardStatsEntity>> call(GetDashboardStatsParams params) {
    return _repository.getStats(academyId: params.academyId);
  }
}
