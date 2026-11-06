import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/groups/data/models/group_model.dart';

abstract class GroupsRemoteDatasource {
  Future<
      ({
        List<GroupModel> groups,
        int total,
        int page,
        int totalPages,
      })> getGroups({
    String? academyId,
    String? sportId,
    int page = 1,
    int limit = 20,
  });

  Future<List<GroupModel>> getGroupsByAcademy({
    required String academyId,
    String? sportId,
  });

  Future<List<GroupModel>> getGroupsBySport(String sportId);

  Future<GroupModel> getGroupById(String id);

  Future<GroupModel> createGroup({
    required String name,
    String? academyId,
    String? sportId,
    String? ageGroup,
    int? capacity,
  });

  Future<GroupModel> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    bool? isActive,
    String? sportId,
  });

  Future<void> deleteGroup(String id);

  Future<void> reorderGroups({
    required String academyId,
    required List<String> orderedIds,
  });
}

class GroupsRemoteDatasourceImpl implements GroupsRemoteDatasource {
  final ApiClient _apiClient;

  GroupsRemoteDatasourceImpl(this._apiClient);

  @override
  Future<
      ({
        List<GroupModel> groups,
        int total,
        int page,
        int totalPages,
      })> getGroups({
    String? academyId,
    String? sportId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (academyId != null) 'academyId': academyId,
      if (sportId != null && sportId.isNotEmpty) 'sportId': sportId,
    };

    final response = await _apiClient.get('/groups', queryParameters: queryParams);
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;

    return (
      groups: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<List<GroupModel>> getGroupsByAcademy({
    required String academyId,
    String? sportId,
  }) async {
    final queryParams = <String, dynamic>{
      if (sportId != null && sportId.isNotEmpty) 'sportId': sportId,
    };
    final response = await _apiClient.get(
      '/groups/academy/$academyId',
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as List<dynamic>)
        .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<GroupModel>> getGroupsBySport(String sportId) async {
    final response = await _apiClient.get('/groups/sport/$sportId');
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as List<dynamic>)
        .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GroupModel> getGroupById(String id) async {
    final response = await _apiClient.get('/groups/$id');
    final body = response.data as Map<String, dynamic>;
    return GroupModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    String? academyId,
    String? sportId,
    String? ageGroup,
    int? capacity,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      if (academyId != null) 'academyId': academyId,
      if (sportId != null && sportId.isNotEmpty) 'sportId': sportId,
      if (ageGroup != null && ageGroup.isNotEmpty) 'ageGroup': ageGroup,
      if (capacity != null) 'capacity': capacity,
    };
    final response = await _apiClient.post('/groups', data: data);
    final body = response.data as Map<String, dynamic>;
    return GroupModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<GroupModel> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    bool? isActive,
    String? sportId,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (ageGroup != null) 'ageGroup': ageGroup,
      if (capacity != null) 'capacity': capacity,
      if (isActive != null) 'isActive': isActive,
      if (sportId != null) 'sportId': sportId,
    };
    final response = await _apiClient.patch('/groups/$id', data: data);
    final body = response.data as Map<String, dynamic>;
    return GroupModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteGroup(String id) async {
    await _apiClient.delete('/groups/$id');
  }

  @override
  Future<void> reorderGroups({
    required String academyId,
    required List<String> orderedIds,
  }) async {
    await _apiClient.patch('/groups/reorder', data: {
      'academyId': academyId,
      'orderedIds': orderedIds,
    });
  }
}
