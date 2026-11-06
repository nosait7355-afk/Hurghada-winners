import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/core/layout/desktop_scaffold.dart';
import 'package:hurghada_winners/core/layout/responsive.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_detail_screen.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/player_subscription_history_screen.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/renew_subscription_screen.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum _SubFilter { all, active, expiringSoon, expired }

class SubscriptionsListScreen extends ConsumerStatefulWidget {
  /// معرّف الفرع، أو [AppConstants.allAcademiesId] لاشتراكات كل الفروع.
  final String academyId;

  /// فلتر الحالة المبدئي: 'active' | 'expiringSoon' | 'expired'.
  final String? initialFilter;

  const SubscriptionsListScreen({
    super.key,
    required this.academyId,
    this.initialFilter,
  });

  @override
  ConsumerState<SubscriptionsListScreen> createState() =>
      _SubscriptionsListScreenState();
}

class _SubscriptionsListScreenState
    extends ConsumerState<SubscriptionsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  _SubFilter _filter = _SubFilter.all;
  String? _branchId;

  bool get _isAllBranches => widget.academyId == AppConstants.allAcademiesId;

  @override
  void initState() {
    super.initState();
    _filter = _SubFilter.values.firstWhere(
      (f) => f.name == widget.initialFilter,
      orElse: () => _SubFilter.all,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SubscriptionEntity> _applyFilters(List<SubscriptionEntity> all) {
    var result = all;

    if (_branchId != null) {
      result = result.where((s) => s.academyId == _branchId).toList();
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      result = result.where((s) {
        return s.playerName.toLowerCase().contains(q) ||
            s.playerCode.toLowerCase().contains(q) ||
            (s.playerPhone ?? '').toLowerCase().contains(q);
      }).toList();
    }

    // فلاتر الحالة تخص اللاعب لا الاشتراك: نعتمد آخر اشتراك لكل لاعب، وإلا
    // بقي الاشتراك القديم المنتهي لمن جدّد ظاهراً في "المنتهي".
    if (_filter != _SubFilter.all) result = _latestPerPlayer(result);

    switch (_filter) {
      case _SubFilter.all:
        break;
      case _SubFilter.active:
        result = result.where((s) => s.isActive && !s.isExpiringSoon).toList();
        break;
      case _SubFilter.expiringSoon:
        result = result.where((s) => s.isExpiringSoon).toList();
        break;
      case _SubFilter.expired:
        result = result.where((s) => !s.isActive).toList();
        break;
    }

    return result;
  }

  /// الاشتراك ذو تاريخ النهاية الأبعد لكل لاعب، بترتيب القائمة الأصلي.
  static List<SubscriptionEntity> _latestPerPlayer(List<SubscriptionEntity> subs) {
    final latest = <String, SubscriptionEntity>{};
    for (final s in subs) {
      final current = latest[s.playerId];
      if (current == null || s.endDate.isAfter(current.endDate)) {
        latest[s.playerId] = s;
      }
    }
    return latest.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final subsAsync =
        ref.watch(academySubscriptionsProvider(widget.academyId));
    final academies = _isAllBranches
        ? (ref.watch(academiesProvider).valueOrNull ?? const [])
        : const [];
    final branchNames = <String, String>{
      for (final a in academies) a.id as String: a.name as String,
    };
    final title = _isAllBranches ? 'اشتراكات كل الفروع' : 'الاشتراكات';

    final tier =
        kIsWeb ? screenTierOf(MediaQuery.sizeOf(context).width) : ScreenTier.mobile;

    final content = subsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('حدث خطأ: $err')),
      data: (all) {
        final filtered = _applyFilters(all);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchAndFilters(
              controller: _searchController,
              onSearchChanged: (v) => setState(() => _search = v),
              selected: _filter,
              onFilterSelected: (f) => setState(() => _filter = f),
            ),
            if (_isAllBranches && branchNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'كل الفروع',
                      selected: _branchId == null,
                      onTap: () => setState(() => _branchId = null),
                    ),
                    for (final entry in branchNames.entries) ...[
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: entry.value,
                        selected: _branchId == entry.key,
                        onTap: () => setState(() => _branchId = entry.key),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text('لا توجد اشتراكات مطابقة')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _SubscriptionCard(
                  subscription: filtered[i],
                  academyId: widget.academyId,
                  branchName:
                      _isAllBranches ? branchNames[filtered[i].academyId] : null,
                  onChanged: () => ref
                      .read(academySubscriptionsProvider(widget.academyId)
                          .notifier)
                      .refresh(),
                ),
              ),
          ],
        );
      },
    );

    if (tier != ScreenTier.mobile) {
      return DesktopScaffold(
        location:
            AppRoutes.subscriptionsList.replaceFirst(':id', widget.academyId),
        tier: tier,
        title: title,
        content: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(academySubscriptionsProvider(widget.academyId).notifier)
            .refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: content,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search + status filter chips
// ---------------------------------------------------------------------------

class _SearchAndFilters extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final _SubFilter selected;
  final ValueChanged<_SubFilter> onFilterSelected;

  const _SearchAndFilters({
    required this.controller,
    required this.onSearchChanged,
    required this.selected,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'بحث بالاسم أو كود اللاعب أو رقم الهاتف...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.grey200),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'الكل',
                selected: selected == _SubFilter.all,
                onTap: () => onFilterSelected(_SubFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'النشطة',
                selected: selected == _SubFilter.active,
                onTap: () => onFilterSelected(_SubFilter.active),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'تنتهي خلال 7 أيام',
                selected: selected == _SubFilter.expiringSoon,
                onTap: () => onFilterSelected(_SubFilter.expiringSoon),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'المنتهية',
                selected: selected == _SubFilter.expired,
                onTap: () => onFilterSelected(_SubFilter.expired),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? AppColors.white : AppColors.grey700,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.grey200,
      ),
      checkmarkColor: AppColors.white,
    );
  }
}

// ---------------------------------------------------------------------------
// Subscription card
// ---------------------------------------------------------------------------

class _SubscriptionCard extends ConsumerWidget {
  final SubscriptionEntity subscription;

  /// معرّف القائمة (قد يكون 'all') — للـ provider فقط. شاشات اللاعب
  /// والتجديد تستخدم subscription.academyId الحقيقي.
  final String academyId;
  final String? branchName;
  final VoidCallback onChanged;

  const _SubscriptionCard({
    required this.subscription,
    required this.academyId,
    required this.onChanged,
    this.branchName,
  });

  Color get _statusColor {
    switch (subscription.displayStatus) {
      case 'نشط':
        return AppColors.success;
      case 'ينتهي قريباً':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الاشتراك'),
        content: Text(
          'هل تريد حذف اشتراك "${subscription.playerName.isNotEmpty ? subscription.playerName : 'اللاعب'}"؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await ref
        .read(academySubscriptionsProvider(academyId).notifier)
        .deleteSubscription(subscription.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم حذف الاشتراك بنجاح'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerDetailScreen(
          playerId: subscription.playerId,
          academyId: subscription.academyId,
        ),
      ),
    );
  }

  // تذكير ولي الأمر برسالة واتساب جاهزة (المنتهي أو قارب على الانتهاء).
  // playerPhone هنا هو parentPhone القادم من الباك إند.
  Future<void> _sendReminder(BuildContext context) async {
    final s = subscription;
    final phone = s.playerPhone?.trim() ?? '';
    final messenger = ScaffoldMessenger.of(context);
    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('لا يوجد رقم لولي الأمر'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final opened = await WhatsAppUtils.open(
      phone,
      message: WhatsAppUtils.renewalReminderTemplate(
        playerName: s.playerName.isNotEmpty ? s.playerName : 'اللاعب',
        endDate: s.endDate,
      ),
    );
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح واتساب'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    final s = subscription;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPlayer(context),
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: (s.playerImageUrl != null && s.playerImageUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(s.playerImageUrl!)
                : null,
            child: (s.playerImageUrl == null || s.playerImageUrl!.isEmpty)
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.playerName.isNotEmpty ? s.playerName : 'لاعب غير معروف',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (branchName != null)
                  Text('الفرع: $branchName',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                if (s.playerCode.isNotEmpty)
                  Text('كود: ${s.playerCode}',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                const SizedBox(height: 4),
                Text(
                  '${s.amount.toStringAsFixed(0)} | ${dateFormat.format(s.startDate)} → ${dateFormat.format(s.endDate)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
                if (s.isActive)
                  Text(
                    'الأيام المتبقية: ${s.daysRemaining}',
                    style: TextStyle(fontSize: 12, color: _statusColor),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openPlayer(context),
                      icon: const Icon(Icons.person_outline, size: 16),
                      label: const Text('عرض اللاعب', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerSubscriptionHistoryScreen(
                            playerId: s.playerId,
                            academyId: s.academyId,
                            playerName: s.playerName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('سجل الاشتراكات', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RenewSubscriptionScreen(
                              playerId: s.playerId,
                              academyId: s.academyId,
                              playerName: s.playerName,
                            ),
                          ),
                        );
                        onChanged();
                      },
                      icon: const Icon(Icons.autorenew, size: 16),
                      label: const Text('تجديد', style: TextStyle(fontSize: 12)),
                    ),
                    if (!s.isActive || s.isExpiringSoon)
                      TextButton.icon(
                        onPressed: () => _sendReminder(context),
                        style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366)),
                        icon: const Icon(Icons.chat_outlined, size: 16),
                        label: const Text('تذكير واتساب',
                            style: TextStyle(fontSize: 12)),
                      ),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context, ref),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('حذف', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}
