import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/create_evaluation_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/delete_evaluation_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/get_evaluations_by_player_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/get_latest_evaluation_usecase.dart';
import 'package:hurghada_winners/features/evaluation/domain/usecases/update_evaluation_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// PlayerEvaluationsNotifier
// ---------------------------------------------------------------------------

typedef EvaluationsState = ({
  List<EvaluationEntity> evaluations,
  int total,
  int page,
  int totalPages,
});

class PlayerEvaluationsNotifier
    extends AsyncNotifier<EvaluationsState> {
  late String _playerId;
  // getter (لا late final): build() يُعاد تشغيله عند التحديث على نفس الكائن.
  GetEvaluationsByPlayerUsecase get _getEvaluationsUsecase => sl<GetEvaluationsByPlayerUsecase>();
  CreateEvaluationUsecase get _createEvaluationUsecase => sl<CreateEvaluationUsecase>();
  UpdateEvaluationUsecase get _updateEvaluationUsecase => sl<UpdateEvaluationUsecase>();
  DeleteEvaluationUsecase get _deleteEvaluationUsecase => sl<DeleteEvaluationUsecase>();

  @override
  Future<EvaluationsState> build() async {
    return (evaluations: <EvaluationEntity>[], total: 0, page: 1, totalPages: 1);
  }

  Future<void> setPlayer(String playerId) async {
    _playerId = playerId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchEvaluations());
  }

  Future<EvaluationsState> _fetchEvaluations({int page = 1}) async {
    final result = await _getEvaluationsUsecase(
      GetEvaluationsByPlayerParams(playerId: _playerId, page: page),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => data,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchEvaluations());
  }

  Future<String?> createEvaluation({
    required double fitness,
    required double basicSkills,
    required double attack,
    required double defense,
    required double commitment,
    String? notes,
    String? academyId,
    DateTime? evaluationDate,
    String? playerId,
  }) async {
    if (playerId != null) _playerId = playerId;
    final result = await _createEvaluationUsecase(
      CreateEvaluationParams(
        playerId: _playerId,
        fitness: fitness,
        basicSkills: basicSkills,
        attack: attack,
        defense: defense,
        commitment: commitment,
        notes: notes,
        academyId: academyId,
        evaluationDate: evaluationDate,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> updateEvaluation({
    required String id,
    double? fitness,
    double? basicSkills,
    double? attack,
    double? defense,
    double? commitment,
    String? notes,
    DateTime? evaluationDate,
  }) async {
    final result = await _updateEvaluationUsecase(
      UpdateEvaluationParams(
        id: id,
        fitness: fitness,
        basicSkills: basicSkills,
        attack: attack,
        defense: defense,
        commitment: commitment,
        notes: notes,
        evaluationDate: evaluationDate,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> deleteEvaluation(String id) async {
    final result = await _deleteEvaluationUsecase(
      DeleteEvaluationParams(id: id),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }
}

final playerEvaluationsProvider =
    AsyncNotifierProvider<PlayerEvaluationsNotifier, EvaluationsState>(
  PlayerEvaluationsNotifier.new,
);

// ---------------------------------------------------------------------------
// Latest evaluation per player (FutureProvider.family)
// ---------------------------------------------------------------------------

final latestEvaluationProvider =
    FutureProvider.family<EvaluationEntity?, String>((ref, playerId) async {
  final usecase = sl<GetLatestEvaluationUsecase>();
  final result = await usecase(GetLatestEvaluationParams(playerId: playerId));
  // عند أي خطأ → null (لا توجد تقييمات) بدلاً من throw
  // هذا يضمن ظهور بطاقة التقييم دائماً مع زر "إضافة تقييم"
  return result.fold(
    (failure) => null,
    (entity) => entity,
  );
});
