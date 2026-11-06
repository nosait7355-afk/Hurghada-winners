import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class GetPlayersBirthdaysParams {
  final int month;
  final String? academyId;

  const GetPlayersBirthdaysParams({required this.month, this.academyId});
}

class GetPlayersBirthdaysUsecase
    extends UseCase<List<PlayerEntity>, GetPlayersBirthdaysParams> {
  final PlayerRepository _repository;

  GetPlayersBirthdaysUsecase(this._repository);

  @override
  Future<Either<Failure, List<PlayerEntity>>> call(
      GetPlayersBirthdaysParams params) {
    return _repository.getPlayersBirthdays(
      month: params.month,
      academyId: params.academyId,
    );
  }
}
