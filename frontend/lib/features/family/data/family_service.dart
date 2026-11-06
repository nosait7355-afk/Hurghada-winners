import 'package:hurghada_winners/core/network/api_client.dart';

/// حساب لاعب كعضو في عائلة أو كمرشّح للإضافة.
class FamilyMember {
  final String accountId;
  final String username;
  final bool isActive;
  final String? familyId;
  final String fullName;
  final String playerCode;
  final String? imageUrl;
  final String academyName;

  const FamilyMember({
    required this.accountId,
    required this.username,
    required this.isActive,
    required this.familyId,
    required this.fullName,
    required this.playerCode,
    required this.imageUrl,
    required this.academyName,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
        accountId: j['accountId'] as String,
        username: j['username'] as String? ?? '',
        isActive: j['isActive'] as bool? ?? true,
        familyId: j['familyId'] as String?,
        fullName: j['fullName'] as String? ?? '',
        playerCode: j['playerCode'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
        academyName: j['academyName'] as String? ?? '',
      );
}

class AccountFamily {
  final String id;
  final String name;
  final List<FamilyMember> members;

  const AccountFamily({required this.id, required this.name, required this.members});

  /// اسم للعرض: الاسم المكتوب، أو أسماء الأفراد الأولى.
  String get displayName => name.isNotEmpty
      ? name
      : members.map((m) => m.fullName.split(' ').first).join(' و ');

  factory AccountFamily.fromJson(Map<String, dynamic> j) => AccountFamily(
        id: j['_id'] as String,
        name: j['name'] as String? ?? '',
        members: ((j['members'] as List<dynamic>?) ?? const [])
            .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// إدارة العائلات — السوبر أدمن فقط (الباك إند يفرض ذلك).
class FamilyService {
  final ApiClient _api;
  FamilyService(this._api);

  dynamic _data(dynamic res) => (res.data as Map<String, dynamic>)['data'];

  Future<List<AccountFamily>> list() async {
    final data = _data(await _api.get<Map<String, dynamic>>('/families')) as List<dynamic>;
    return data.map((e) => AccountFamily.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FamilyMember>> searchCandidates(String query) async {
    final data = _data(await _api.get<Map<String, dynamic>>(
      '/families/candidates',
      queryParameters: {'search': query},
    )) as List<dynamic>;
    return data.map((e) => FamilyMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({required List<String> accountIds, String? name}) async {
    await _api.post('/families', data: {
      'accountIds': accountIds,
      if (name != null && name.isNotEmpty) 'name': name,
    });
  }

  Future<void> rename(String familyId, String name) async {
    await _api.patch('/families/$familyId', data: {'name': name});
  }

  Future<void> addMembers(String familyId, List<String> accountIds) async {
    await _api.post('/families/$familyId/members', data: {'accountIds': accountIds});
  }

  Future<void> removeMember(String familyId, String accountId) async {
    await _api.delete('/families/$familyId/members/$accountId');
  }

  Future<void> dissolve(String familyId) async {
    await _api.delete('/families/$familyId');
  }
}
