// اختبار انحدار لمشكلة "صفحة اللاعبين فاضية لحد ما أقفل التطبيق":
// 1) بحث متبقٍ من شاشة اختيار لاعبي المباراة كان يُطبَّق بصمت على قائمة اللاعبين.
// 2) زر التحديث (invalidate) كان يكسر الـ notifier بـ LateInitializationError.
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/domain/repositories/player_repository.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_players_usecase.dart';
import 'package:hurghada_winners/features/player/presentation/providers/player_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoRepo implements PlayerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

PlayerEntity _p(String id, String name, String group) => PlayerEntity(
      id: id,
      academyId: 'A',
      playerCode: id,
      fullName: name,
      birthDate: DateTime(2012),
      parentName: 'ولي',
      parentRelationship: 'أب',
      parentPhone: '0',
      groupId: group,
      createdAt: DateTime(2026),
    );

/// يحاكي الباك إند: يطبّق البحث والمجموعة مثل السيرفر.
class _FakeGetPlayers extends GetPlayersUsecase {
  _FakeGetPlayers() : super(_NoRepo());
  final all = [_p('1', 'أحمد', 'g1'), _p('2', 'محمد', 'g1'), _p('3', 'يوسف', 'g2')];

  @override
  Future<Either<Failure, ({List<PlayerEntity> players, int total, int page, int totalPages})>> call(
      GetPlayersParams params) async {
    final list = all
        .where((p) => params.search == null || p.fullName.contains(params.search!))
        .where((p) => params.groupId == null || p.groupId == params.groupId)
        .toList();
    return Right((players: list, total: list.length, page: 1, totalPages: 1));
  }
}

void main() {
  setUpAll(() => sl.registerSingleton<GetPlayersUsecase>(_FakeGetPlayers()));
  tearDownAll(() => sl.reset());

  test('opening the players page ignores a search left over by the match picker', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(playersProvider.future);
    final n = c.read(playersProvider.notifier);

    // شاشة اختيار لاعبي المباراة: بحث بكلمة لا تطابق إلا لاعباً واحداً.
    await n.openForAcademy('A');
    await n.search('يوسف');
    expect(c.read(playersProvider).value!.players.length, 1);

    // فتح صفحة اللاعبين بعدها: لازم تظهر كل القائمة.
    await n.openForAcademy('A');
    expect(c.read(playersProvider).value!.players.length, 3);
    expect(c.read(playersProvider).value!.search, isNull);
  });

  test('switching branch drops the previous branch group filter', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(playersProvider.future);
    final n = c.read(playersProvider.notifier);
    await n.openForAcademy('A');
    await n.filterByGroup('g2');
    expect(c.read(playersProvider).value!.players.length, 1);
    await n.filterByAcademy('B');
    expect(c.read(playersProvider).value!.groupFilter, isNull);
  });

  test('refresh button (invalidate) does not break the notifier', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(playersProvider.future);
    c.invalidate(playersProvider);
    await c.read(playersProvider.future); // كان يرمي LateInitializationError
    final n = c.read(playersProvider.notifier);
    await n.openForAcademy('A');
    expect(c.read(playersProvider).value!.players.length, 3);
  });
}
