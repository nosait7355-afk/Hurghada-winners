import 'dart:async';

import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/family/data/family_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final familiesProvider = FutureProvider.autoDispose<List<AccountFamily>>((ref) {
  return sl<FamilyService>().list();
});

/// رسالة الخادم إن وُجدت (مثلاً: "الحساب ... ضمن عائلة أخرى بالفعل").
String _errorText(Object e, String fallback) {
  if (e is DioException && e.response?.data is Map) {
    final msg = (e.response!.data as Map)['message'];
    if (msg is String && msg.isNotEmpty) return msg;
  }
  return fallback;
}

void _snack(ScaffoldMessengerState m, String text, {bool error = false}) {
  m.showSnackBar(SnackBar(
    content: Text(text),
    backgroundColor: error ? AppColors.error : AppColors.success,
  ));
}

/// أيقونة تبويب "إضافة عائلة" — للسوبر أدمن في الصفحة الرئيسية.
class FamiliesIconButton extends StatelessWidget {
  final Color? color;
  const FamiliesIconButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'إضافة عائلة',
      color: color,
      icon: const Icon(Icons.family_restroom_outlined),
      onPressed: () => context.push(AppRoutes.families),
    );
  }
}

/// تبويب "إضافة عائلة": دمج حسابات لاعبين (من أي فرع) ليتبادلوا الدخول.
class FamiliesScreen extends ConsumerWidget {
  const FamiliesScreen({super.key});

  Future<void> _newFamily(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FamilyMembersPickerScreen()),
    );
    if (created == true) ref.invalidate(familiesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(familiesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('إضافة عائلة'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newFamily(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('عائلة جديدة'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(familiesProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(children: [
            const SizedBox(height: 120),
            const Center(child: Text('تعذّر تحميل العائلات')),
            Center(
              child: TextButton(
                onPressed: () => ref.invalidate(familiesProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ),
          ]),
          data: (families) {
            if (families.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.family_restroom_outlined, size: 64, color: AppColors.grey300),
                SizedBox(height: 12),
                Center(child: Text('لا توجد عائلات بعد')),
                SizedBox(height: 4),
                Center(
                  child: Text('اضغط "عائلة جديدة" لدمج حسابين أو أكثر',
                      style: TextStyle(color: AppColors.grey500)),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: families.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _FamilyCard(family: families[i]),
            );
          },
        ),
      ),
    );
  }
}

class _FamilyCard extends ConsumerWidget {
  final AccountFamily family;
  const _FamilyCard({required this.family});

  FamilyService get _service => sl<FamilyService>();

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController(text: family.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اسم العائلة'),
        content: TextField(
          controller: ctrl,
          maxLength: 100,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'مثال: عائلة محمد'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('حفظ')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null) return;
    try {
      await _service.rename(family.id, name);
      ref.invalidate(familiesProvider);
      _snack(messenger, 'تم حفظ الاسم');
    } catch (e) {
      _snack(messenger, _errorText(e, 'تعذّر حفظ الاسم'), error: true);
    }
  }

  Future<void> _addMembers(BuildContext context, WidgetRef ref) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FamilyMembersPickerScreen(family: family)),
    );
    if (added == true) ref.invalidate(familiesProvider);
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref, FamilyMember m) async {
    final messenger = ScaffoldMessenger.of(context);
    final willDissolve = family.members.length <= 2;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة من العائلة'),
        content: Text(willDissolve
            ? 'إزالة "${m.fullName}" ستترك حساباً واحداً فقط، لذلك ستُفكّ العائلة بالكامل. متابعة؟'
            : 'إزالة "${m.fullName}" من العائلة؟ لن يتمكن من التبديل لباقي الحسابات.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إزالة', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.removeMember(family.id, m.accountId);
      ref.invalidate(familiesProvider);
      _snack(messenger, willDissolve ? 'تم فكّ العائلة' : 'تمت الإزالة');
    } catch (e) {
      _snack(messenger, _errorText(e, 'تعذّرت الإزالة'), error: true);
    }
  }

  Future<void> _dissolve(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فكّ العائلة'),
        content: Text('فكّ "${family.displayName}"؟ كل حساب سيعود مستقلاً ولن يظهر زر التبديل.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('فكّ العائلة', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.dissolve(family.id);
      ref.invalidate(familiesProvider);
      _snack(messenger, 'تم فكّ العائلة');
    } catch (e) {
      _snack(messenger, _errorText(e, 'تعذّر فكّ العائلة'), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.family_restroom, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  family.displayName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${family.members.length} حسابات',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'rename':
                      _rename(context, ref);
                    case 'add':
                      _addMembers(context, ref);
                    case 'dissolve':
                      _dissolve(context, ref);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'add', child: Text('إضافة حساب')),
                  PopupMenuItem(value: 'rename', child: Text('تعديل الاسم')),
                  PopupMenuItem(
                    value: 'dissolve',
                    child: Text('فكّ العائلة', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 12),
          for (final m in family.members)
            _MemberTile(
              member: m,
              trailing: IconButton(
                tooltip: 'إزالة من العائلة',
                icon: const Icon(Icons.person_remove_outlined, color: AppColors.error, size: 20),
                onPressed: () => _removeMember(context, ref, m),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final FamilyMember member;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _MemberTile({required this.member, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = member;
    final hasImage = m.imageUrl != null && m.imageUrl!.isNotEmpty;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.only(right: 0, left: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryContainer,
        backgroundImage: hasImage ? CachedNetworkImageProvider(m.imageUrl!) : null,
        child: hasImage ? null : const Icon(Icons.person, color: AppColors.primary),
      ),
      title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        [
          if (m.academyName.isNotEmpty) m.academyName,
          if (m.playerCode.isNotEmpty) m.playerCode,
          m.username,
          if (!m.isActive) 'معطّل',
        ].join('  •  '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: trailing,
    );
  }
}

/// اختيار حسابات من كل الفروع: لإنشاء عائلة جديدة، أو للإضافة لعائلة [family].
/// يرجع true عند النجاح.
class FamilyMembersPickerScreen extends StatefulWidget {
  final AccountFamily? family;
  const FamilyMembersPickerScreen({super.key, this.family});

  @override
  State<FamilyMembersPickerScreen> createState() => _FamilyMembersPickerScreenState();
}

class _FamilyMembersPickerScreenState extends State<FamilyMembersPickerScreen> {
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final Map<String, FamilyMember> _selected = {};
  List<FamilyMember> _results = const [];
  Timer? _debounce;
  bool _searching = false;
  bool _saving = false;

  bool get _isCreate => widget.family == null;
  int get _minSelection => _isCreate ? 2 : 1;

  @override
  void initState() {
    super.initState();
    // كل حسابات اللاعبين تظهر فوراً للاختيار؛ البحث للتصفية فقط.
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() => _searching = true);
    try {
      final res = await sl<FamilyService>().searchCandidates(q);
      if (!mounted || _searchCtrl.text.trim() != q) return;
      setState(() => _results = res);
    } catch (_) {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    final q = value.trim();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(q));
  }

  /// سبب عدم إمكانية اختيار الحساب، أو null إن كان متاحاً.
  String? _blockReason(FamilyMember m) {
    if (m.familyId == null) return null;
    if (m.familyId == widget.family?.id) return 'ضمن هذه العائلة';
    return 'ضمن عائلة أخرى';
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final ids = _selected.keys.toList();
    setState(() => _saving = true);
    try {
      final service = sl<FamilyService>();
      if (_isCreate) {
        await service.create(accountIds: ids, name: _nameCtrl.text.trim());
      } else {
        await service.addMembers(widget.family!.id, ids);
      }
      _snack(messenger, _isCreate ? 'تم دمج الحسابات في عائلة' : 'تمت إضافة الحسابات');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack(messenger, _errorText(e, 'تعذّر الحفظ'), error: true);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_saving && _selected.length >= _minSelection;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isCreate ? 'عائلة جديدة' : 'إضافة إلى ${widget.family!.displayName}'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: [
                if (_isCreate) ...[
                  TextField(
                    controller: _nameCtrl,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'اسم العائلة (اختياري)',
                      hintText: 'مثال: عائلة محمد',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'تصفية بالاسم أو الكود أو رقم ولي الأمر أو اسم المستخدم',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in _selected.values)
                    InputChip(
                      label: Text(m.fullName.split(' ').first),
                      onDeleted: () => setState(() => _selected.remove(m.accountId)),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: _searching
                        ? const CircularProgressIndicator()
                        : Text(
                            _searchCtrl.text.trim().isEmpty
                                ? 'لا توجد حسابات لاعبين بعد'
                                : 'لا توجد حسابات مطابقة',
                            style: const TextStyle(color: AppColors.grey500),
                          ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final m = _results[i];
                      final blocked = _blockReason(m);
                      final checked = _selected.containsKey(m.accountId);
                      return Opacity(
                        opacity: blocked == null ? 1 : 0.5,
                        child: _MemberTile(
                          member: m,
                          onTap: blocked != null
                              ? null
                              : () => setState(() => checked
                                  ? _selected.remove(m.accountId)
                                  : _selected[m.accountId] = m),
                          trailing: blocked != null
                              ? Text(blocked,
                                  style: const TextStyle(fontSize: 11, color: AppColors.grey500))
                              : Checkbox(
                                  value: checked,
                                  onChanged: (_) => setState(() => checked
                                      ? _selected.remove(m.accountId)
                                      : _selected[m.accountId] = m),
                                ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: canSave ? _save : null,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.merge_type),
                  label: Text(_isCreate
                      ? (_selected.length < 2
                          ? 'اختر حسابين على الأقل (${_selected.length})'
                          : 'دمج ${_selected.length} حسابات')
                      : 'إضافة ${_selected.length} حساب'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
