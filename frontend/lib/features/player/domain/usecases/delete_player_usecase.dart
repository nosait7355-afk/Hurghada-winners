import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class DeletePlayerParams {
  final String id;

  const DeletePlayerParams({required this.id});
}

class DeletePlayerUsecase extends UseCase<void, DeletePlayerParams> {
  final PlayerRepository _repository;

  DeletePlayerUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeletePlayerParams params) {
    return _repository.deletePlayer(params.id);
  }
}
