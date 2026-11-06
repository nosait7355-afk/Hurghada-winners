import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/presentation/providers/groups_provider.dart';
import 'package:hurghada_winners/features/groups/presentation/screens/create_group_screen.dart';
import 'package:hurghada_winners/features/groups/presentation/screens/edit_group_screen.dart';
import 'package:hurghada_winners/features/groups/presentation/screens/group_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// شاشة المجموعات — قائمة مسطّحة بسيطة لأقسام الأكاديمية التنظيمية.
/// المجموعات مستقلة تماماً عن الرياضة: لا أقسام رياضة، لا فئة عمرية.
class GroupsListScreen extends ConsumerStatefulWidget {
  final String academyId;

  const GroupsListScreen({super.key, required this.academyId});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsProvider.notifier).filterByAcademy(widget.academyId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // صلاحية إدارة مجموعات هذه الأكاديمية: super_admin مطلقاً، أو مستوى أكاديمية
  // (academy_admin / admin) على أكاديميته فقط — مطابق لصلاحيات الـ backend.
  bool _canManage() {
    final user = ref.read(authStateProvider).valueOrNull?.user;
    if (user == null) return false;
    if (user.isSuperAdmin) return true;
    return user.isAcademyLevel && user.academyId == widget.academyId;
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(academyId: widget.academyId),
      ),
    );
  }

  Future<void> _openEdit(GroupEntity group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditGroupScreen(group: group)),
    );
  }

  void _openPlayers(GroupEntity group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(
          academyId: widget.academyId,
          groupId: group.id,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(GroupEntity group) async {
    // حارس على العميل: لا يُسمح بحذف مجموعة تحتوي لاعبين (الخادم يمنع أيضاً 409).
    if (group.playersCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'لا يمكن حذف المجموعة لأنها تحتوي على لاعبين. قم بنقل اللاعبين أولاً.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المجموعة'),
        content: Text('هل أنت متأكد من حذف "${group.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref.read(groupsProvider.notifier).deleteGroup(group.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم حذف المجموعة'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _onReorder(List<GroupEntity> sectionGroups, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final ids = sectionGroups.map((g) => g.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    ref.read(groupsProvider.notifier).reorderGroups(
          academyId: widget.academyId,
          orderedIds: ids,
        );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final canManage = _canManage();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المجموعات'), centerTitle: true),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('مجموعة'),
            )
          : null,
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                const SizedBox(height: 12),
                Text(err.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref
                      .read(groupsProvider.notifier)
                      .filterByAcademy(widget.academyId),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          final all = [...state.groups]
            ..sort((a, b) => a.order.compareTo(b.order));
          final query = _search.trim().toLowerCase();
          final groups = query.isEmpty
              ? all
              : all
                  .where((g) => g.name.toLowerCase().contains(query))
                  .toList();

          return Column(
            children: [
              // شريط البحث بالاسم.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث باسم المجموعة',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(groupsProvider.notifier).refresh(),
                  child: groups.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            const Icon(Icons.groups_2_outlined,
                                size: 64, color: AppColors.grey300),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                query.isEmpty
                                    ? 'لا توجد مجموعات بعد'
                                    : 'لا توجد نتائج للبحث',
                                style: const TextStyle(
                                    color: AppColors.grey500, fontSize: 14),
                              ),
                            ),
                          ],
                        )
                      // السحب والإفلات لإعادة الترتيب متاح فقط دون بحث نشط.
                      : (canManage && groups.length > 1 && query.isEmpty)
                          ? ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              itemCount: groups.length,
                              // ignore: deprecated_member_use
                              onReorder: (o, n) => _onReorder(groups, o, n),
                              itemBuilder: (context, index) {
                                final group = groups[index];
                                return Padding(
                                  key: ValueKey(group.id),
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _GroupCard(
                                    group: group,
                                    canManage: canManage,
                                    draggable: true,
                                    onPlayers: () => _openPlayers(group),
                                    onEdit: () => _openEdit(group),
                                    onDelete: () => _confirmDelete(group),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: groups.length,
                              itemBuilder: (context, index) {
                                final group = groups[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _GroupCard(
                                    group: group,
                                    canManage: canManage,
                                    draggable: false,
                                    onPlayers: () => _openPlayers(group),
                                    onEdit: () => _openEdit(group),
                                    onDelete: () => _confirmDelete(group),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupEntity group;
  final bool canManage;
  final bool draggable;
  final VoidCallback onPlayers;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.canManage,
    required this.draggable,
    required this.onPlayers,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _occupationColor {
    final rate = group.occupationRate ?? 0;
    if (rate >= 90) return AppColors.error;
    if (rate >= 70) return Colors.orange;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = group.remainingSeats;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (draggable) ...[
                  const Icon(Icons.drag_indicator,
                      size: 20, color: AppColors.grey400),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (group.isFull)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('ممتلئة',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error)),
                  )
                else if (!group.isActive)
                  const Icon(Icons.pause_circle_outline,
                      color: AppColors.grey400, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 16, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text(
                  group.capacity != null
                      ? '${group.playersCount} / ${group.capacity} لاعب'
                      : '${group.playersCount} لاعب',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.grey700),
                ),
                const Spacer(),
                if (remaining != null)
                  Text(
                    'متبقٍ: $remaining',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: remaining == 0
                          ? AppColors.error
                          : AppColors.grey600,
                    ),
                  ),
              ],
            ),
            if (group.occupationRate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (group.occupationRate!.clamp(0, 100)) / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.grey200,
                        color: _occupationColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${group.occupationRate}%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _occupationColor)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onPlayers,
                  icon: const Icon(Icons.people_alt_outlined, size: 18),
                  label: const Text('اللاعبون'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const Spacer(),
                if (canManage) ...[
                  IconButton(
                    tooltip: 'تعديل',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.primary,
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
