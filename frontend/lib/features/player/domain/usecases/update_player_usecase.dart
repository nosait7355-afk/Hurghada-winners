import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/core/utils/usecase.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class UpdatePlayerParams {
  final String id;
  final String? fullName;
  final DateTime? birthDate;
  final String? parentName;
  final String? parentRelationship;
  final String? parentJob;
  final String? parentPhone;
  final String? playerPhone;
  final String? notes;
  final String? sport;
  final List<String>? attendanceDays;
  final String? imagePath;
  final String? groupId;

  const UpdatePlayerParams({
    required this.id,
    this.fullName,
    this.birthDate,
    this.parentName,
    this.parentRelationship,
    this.parentJob,
    this.parentPhone,
    this.playerPhone,
    this.notes,
    this.sport,
    this.attendanceDays,
    this.imagePath,
    this.groupId,
  });
}

class UpdatePlayerUsecase extends UseCase<PlayerEntity, UpdatePlayerParams> {
  final PlayerRepository _repository;

  UpdatePlayerUsecase(this._repository);

  @override
  Future<Either<Failure, PlayerEntity>> call(UpdatePlayerParams params) {
    return _repository.updatePlayer(
      id: params.id,
      fullName: params.fullName,
      birthDate: params.birthDate,
      parentName: params.parentName,
      parentRelationship: params.parentRelationship,
      parentJob: params.parentJob,
      parentPhone: params.parentPhone,
      playerPhone: params.playerPhone,
      notes: params.notes,
      sport: params.sport,
      attendanceDays: params.attendanceDays,
      imagePath: params.imagePath,
      groupId: params.groupId,
    );
  }
}
