import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:hurghada_winners/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetRevenueByMonthParams {
  final String? academyId;
  const GetRevenueByMonthParams({this.academyId});
}

class GetRevenueByMonthUsecase extends UseCase<List<RevenueByMonthEntity>, GetRevenueByMonthParams> {
  final DashboardRepository _repository;

  GetRevenueByMonthUsecase(this._repository);

  @override
  Future<Either<Failure, List<RevenueByMonthEntity>>> call(GetRevenueByMonthParams params) {
    return _repository.getRevenueByMonth(academyId: params.academyId);
  }
}
