import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class SearchPlayersParams {
  final String query;

  const SearchPlayersParams({required this.query});
}

class SearchPlayersUsecase
    extends UseCase<List<PlayerEntity>, SearchPlayersParams> {
  final PlayerRepository _repository;

  SearchPlayersUsecase(this._repository);

  @override
  Future<Either<Failure, List<PlayerEntity>>> call(
      SearchPlayersParams params) {
    return _repository.searchPlayers(params.query);
  }
}
