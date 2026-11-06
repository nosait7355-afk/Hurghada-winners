import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/groups/data/group_move_service.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/domain/usecases/get_group_usecase.dart';
import 'package:hurghada_winners/features/groups/presentation/providers/groups_provider.dart';
import 'package:hurghada_winners/features/groups/presentation/screens/edit_group_screen.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/domain/usecases/get_players_usecase.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _groupDetailProvider =
    FutureProvider.autoDispose.family<GroupEntity, String>((ref, id) async {
  final usecase = sl<GetGroupUsecase>();
  final result = await usecase(GetGroupParams(id: id));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (group) => group,
  );
});

final _groupPlayersProvider = FutureProvider.autoDispose
    .family<List<PlayerEntity>, ({String academyId, String groupId})>((ref, params) async {
  final usecase = sl<GetPlayersUsecase>();
  final result = await usecase(
    GetPlayersParams(
      academyId: params.academyId,
      groupId: params.groupId,
      limit: 200,
    ),
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data.players,
  );
});

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String academyId;
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.academyId,
    required this.groupId,
  });

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  bool _selectionMode = false;
  final Set<String> _selected = {};
  bool _moving = false;

  void _toggleSelection(String playerId) {
    setState(() {
      if (_selected.contains(playerId)) {
        _selected.remove(playerId);
      } else {
        _selected.add(playerId);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  void _refreshAll() {
    ref.invalidate(_groupDetailProvider(widget.groupId));
    ref.invalidate(_groupPlayersProvider(
        (academyId: widget.academyId, groupId: widget.groupId)));
    ref.read(groupsProvider.notifier).refresh();
  }

  Future<void> _confirmDelete(BuildContext context, GroupEntity group) async {
    // حارس على العميل: منع حذف مجموعة تحتوي لاعبين (الخادم يمنع أيضاً 409).
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
    if (confirmed != true || !context.mounted) return;

    final error = await ref.read(groupsProvider.notifier).deleteGroup(group.id);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  // نقل اللاعبين المحددين إلى أي مجموعة أخرى في الأكاديمية (لا تحقق رياضة).
  Future<void> _moveSelected(GroupEntity currentGroup) async {
    if (_selected.isEmpty) return;
    final destGroupId = await showDialog<String>(
      context: context,
      builder: (ctx) => _MoveTargetDialog(
        academyId: widget.academyId,
        excludeGroupId: currentGroup.id,
      ),
    );
    if (destGroupId == null || !mounted) return;

    setState(() => _moving = true);
    final service = sl<GroupMoveService>();
    final errors = await service.moveMany(
      playerIds: _selected.toList(),
      groupId: destGroupId,
    );
    if (!mounted) return;
    setState(() => _moving = false);

    final movedCount = _selected.length - errors.length;
    _exitSelection();
    _refreshAll();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errors.isEmpty
            ? 'تم نقل $movedCount لاعب بنجاح'
            : 'تم نقل $movedCount، وتعذّر نقل ${errors.length}'),
        backgroundColor: errors.isEmpty ? AppColors.success : AppColors.warning,
      ),
    );
  }

  Color _occupationColor(int rate) {
    if (rate >= 90) return AppColors.error;
    if (rate >= 70) return Colors.orange;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(_groupDetailProvider(widget.groupId));
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;
    final canEdit = isSuperAdmin ||
        (authState?.user?.isAcademyLevel == true &&
            authState?.user?.academyId == widget.academyId);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_selectionMode
            ? 'تحديد (${_selected.length})'
            : 'تفاصيل المجموعة'),
        centerTitle: true,
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelection,
              )
            : null,
        actions: [
          if (!_selectionMode)
            groupAsync.whenOrNull(
                  data: (group) => Row(
                    children: [
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditGroupScreen(group: group),
                            ),
                          ).then((_) => ref
                              .invalidate(_groupDetailProvider(widget.groupId))),
                        ),
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          onPressed: () => _confirmDelete(context, group),
                        ),
                    ],
                  ),
                ) ??
                const SizedBox.shrink(),
        ],
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          final message = err.toString().contains('غير موجود')
              ? 'المجموعة غير موجودة، قد تكون قد حُذفت'
              : err.toString();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
        data: (group) {
          final rate = group.occupationRate;
          final remaining = group.remainingSeats;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (group.isFull)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('ممتلئة',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  )),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: group.isActive
                                    ? AppColors.successLight
                                    : AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                group.isActive ? 'نشطة' : 'غير نشطة',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: group.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        group.capacity != null
                            ? 'عدد اللاعبين: ${group.playersCount} من ${group.capacity}'
                            : 'عدد اللاعبين: ${group.playersCount}',
                        style: const TextStyle(color: AppColors.grey600),
                      ),
                      if (remaining != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'المقاعد المتبقية: $remaining',
                          style: TextStyle(
                            color: remaining == 0
                                ? AppColors.error
                                : AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (rate != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: rate.clamp(0, 100) / 100,
                            minHeight: 8,
                            backgroundColor: AppColors.grey200,
                            color: _occupationColor(rate),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('نسبة الإشغال: $rate%',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.grey500)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('اللاعبون',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  if (canEdit && !_selectionMode)
                    TextButton.icon(
                      onPressed: () => setState(() => _selectionMode = true),
                      icon: const Icon(Icons.checklist, size: 18),
                      label: const Text('تحديد للنقل'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final playersAsync = ref.watch(_groupPlayersProvider(
                      (academyId: widget.academyId, groupId: group.id)));
                  return playersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(err.toString(),
                          style: const TextStyle(color: AppColors.error)),
                    ),
                    data: (players) {
                      if (players.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('لا يوجد لاعبون في هذه المجموعة',
                              style: TextStyle(color: AppColors.grey500)),
                        );
                      }
                      return Column(
                        children: players.map((player) {
                          final selected = _selected.contains(player.id);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: _selectionMode
                                  ? Checkbox(
                                      value: selected,
                                      onChanged: (_) =>
                                          _toggleSelection(player.id),
                                    )
                                  : null,
                              title: Text(player.fullName),
                              subtitle: Text(player.playerCode),
                              trailing: _selectionMode
                                  ? null
                                  : const Icon(Icons.chevron_left),
                              selected: selected,
                              selectedTileColor: AppColors.primaryContainer,
                              onTap: _selectionMode
                                  ? () => _toggleSelection(player.id)
                                  : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PlayerDetailScreen(
                                            playerId: player.id,
                                            academyId: widget.academyId,
                                          ),
                                        ),
                                      ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _selectionMode
          ? groupAsync.whenOrNull(
              data: (group) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: (_selected.isEmpty || _moving)
                        ? null
                        : () => _moveSelected(group),
                    icon: _moving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.drive_file_move_outline),
                    label: Text('نقل المحدد (${_selected.length})'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// حوار اختيار المجموعة الهدف — يعرض كل مجموعات الأكاديمية (عدا المجموعة الحالية).
class _MoveTargetDialog extends ConsumerWidget {
  final String academyId;
  final String excludeGroupId;

  const _MoveTargetDialog({
    required this.academyId,
    required this.excludeGroupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(
      groupsByAcademyProvider((academyId: academyId, sportId: null)),
    );
    return AlertDialog(
      title: const Text('نقل إلى مجموعة'),
      content: SizedBox(
        width: double.maxFinite,
        child: groupsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => const Text('تعذّر تحميل المجموعات',
              style: TextStyle(color: AppColors.error)),
          data: (groups) {
            final targets =
                groups.where((g) => g.id != excludeGroupId).toList();
            if (targets.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا توجد مجموعة أخرى للنقل إليها'),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: targets.map((g) {
                final full = g.isFull;
                return ListTile(
                  title: Text(g.name),
                  subtitle: Text(g.capacity != null
                      ? '${g.playersCount} / ${g.capacity}${full ? ' — ممتلئة' : ''}'
                      : '${g.playersCount} لاعب'),
                  enabled: !full,
                  onTap: full ? null : () => Navigator.of(context).pop(g.id),
                );
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
