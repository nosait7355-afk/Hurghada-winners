import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/create_group_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/delete_group_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/get_groups_by_academy_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/get_groups_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/update_group_usecase.dart';
import 'package:hurghada_winners/features/groups/domain/repositories/groups_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// GroupsState
// ---------------------------------------------------------------------------

class GroupsState {
  final List<GroupEntity> groups;
  final int total;
  final int page;
  final int totalPages;
  final String? academyIdFilter;
  final String? sportIdFilter;

  const GroupsState({
    this.groups = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.academyIdFilter,
    this.sportIdFilter,
  });

  GroupsState copyWith({
    List<GroupEntity>? groups,
    int? total,
    int? page,
    int? totalPages,
    Object? academyIdFilter = _sentinel,
    Object? sportIdFilter = _sentinel,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      academyIdFilter: academyIdFilter == _sentinel
          ? this.academyIdFilter
          : academyIdFilter as String?,
      sportIdFilter: sportIdFilter == _sentinel
          ? this.sportIdFilter
          : sportIdFilter as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// GroupsNotifier
// ---------------------------------------------------------------------------

class GroupsNotifier extends AsyncNotifier<GroupsState> {
  // getter (لا late final): build() يُعاد تشغيله عند التحديث على نفس الكائن.
  GetGroupsUsecase get _getGroupsUsecase => sl<GetGroupsUsecase>();
  CreateGroupUsecase get _createGroupUsecase => sl<CreateGroupUsecase>();
  UpdateGroupUsecase get _updateGroupUsecase => sl<UpdateGroupUsecase>();
  DeleteGroupUsecase get _deleteGroupUsecase => sl<DeleteGroupUsecase>();

  // آخر سياق أكاديمية/رياضة معروف — يُحفظ على المُشغّل نفسه لا في الحالة،
  // لأن AsyncValue.loading()/error تمسح valueOrNull فيضيع academyId عند إعادة
  // المحاولة/التحديث (كان يُرسل GET /groups بدون academyId → 400 للـ super_admin).
  String? _academyId;
  String? _sportId;

  @override
  Future<GroupsState> build() async {
    return const GroupsState();
  }

  Future<GroupsState> _fetch({
    String? academyIdFilter,
    String? sportIdFilter,
    int page = 1,
    int limit = 100,
  }) async {
    // احفظ السياق قبل أي طلب حتى ينجو من حالات loading/error.
    _academyId = academyIdFilter;
    _sportId = sportIdFilter;
    final result = await _getGroupsUsecase(
      GetGroupsParams(
        academyId: academyIdFilter,
        sportId: sportIdFilter,
        page: page,
        limit: limit,
      ),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => GroupsState(
        groups: data.groups,
        total: data.total,
        page: data.page,
        totalPages: data.totalPages,
        academyIdFilter: academyIdFilter,
        sportIdFilter: sportIdFilter,
      ),
    );
  }

  Future<void> refresh() async {
    // يستخدم آخر سياق محفوظ على المُشغّل (لا valueOrNull) فلا يضيع academyId
    // حتى لو كانت الحالة الحالية خطأً/تحميلاً — نفس طلب أول تحميل ناجح.
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetch(academyIdFilter: _academyId, sportIdFilter: _sportId),
    );
  }

  Future<void> filterByAcademy(String? academyId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetch(academyIdFilter: academyId, sportIdFilter: _sportId),
    );
  }

  Future<void> filterBySport(String? sportId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetch(academyIdFilter: _academyId, sportIdFilter: sportId),
    );
  }

  Future<String?> createGroup({
    required String name,
    String? academyId,
    String? sportId,
    String? ageGroup,
    int? capacity,
  }) async {
    final result = await _createGroupUsecase(
      CreateGroupParams(
        name: name,
        academyId: academyId,
        sportId: sportId,
        ageGroup: ageGroup,
        capacity: capacity,
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

  Future<String?> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    bool? isActive,
    String? sportId,
  }) async {
    final result = await _updateGroupUsecase(
      UpdateGroupParams(
        id: id,
        name: name,
        ageGroup: ageGroup,
        capacity: capacity,
        isActive: isActive,
        sportId: sportId,
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

  Future<String?> deleteGroup(String id) async {
    final result = await _deleteGroupUsecase(DeleteGroupParams(id: id));
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  /// إعادة ترتيب مجموعات (سحب وإفلات) — تحديث تفاؤلي محلي ثم مزامنة مع الخادم.
  Future<String?> reorderGroups({
    required String academyId,
    required List<String> orderedIds,
  }) async {
    final current = state.valueOrNull;
    if (current != null) {
      final orderMap = <String, int>{
        for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
      };
      final updated = current.groups
          .map((g) => orderMap.containsKey(g.id)
              ? g.copyWith(order: orderMap[g.id])
              : g)
          .toList();
      state = AsyncValue.data(current.copyWith(groups: updated));
    }

    final result = await sl<GroupsRepository>().reorderGroups(
      academyId: academyId,
      orderedIds: orderedIds,
    );
    return result.fold(
      (failure) {
        refresh(); // تراجع عند الفشل
        return failure.message;
      },
      (_) => null,
    );
  }
}

final groupsProvider =
    AsyncNotifierProvider<GroupsNotifier, GroupsState>(GroupsNotifier.new);

// ---------------------------------------------------------------------------
// groupsByAcademyProvider — lightweight list for dropdowns/filters
// ---------------------------------------------------------------------------

final groupsByAcademyProvider = FutureProvider.autoDispose
    .family<List<GroupEntity>, ({String academyId, String? sportId})>(
        (ref, params) async {
  final usecase = sl<GetGroupsByAcademyUsecase>();
  final result = await usecase(
    GetGroupsByAcademyParams(
      academyId: params.academyId,
      sportId: params.sportId,
    ),
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (groups) => groups,
  );
});
