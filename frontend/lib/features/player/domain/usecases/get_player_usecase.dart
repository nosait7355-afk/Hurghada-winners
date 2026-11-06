import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class GetPlayerParams {
  final String id;

  const GetPlayerParams({required this.id});
}

class GetPlayerUsecase extends UseCase<PlayerEntity, GetPlayerParams> {
  final PlayerRepository _repository;

  GetPlayerUsecase(this._repository);

  @override
  Future<Either<Failure, PlayerEntity>> call(GetPlayerParams params) {
    return _repository.getPlayerById(params.id);
  }
}
