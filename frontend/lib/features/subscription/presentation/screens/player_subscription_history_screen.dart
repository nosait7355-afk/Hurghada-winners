import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/currency_provider.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/renew_subscription_screen.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/subscription_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class PlayerSubscriptionHistoryScreen extends ConsumerStatefulWidget {
  final String playerId;
  final String academyId;
  final String playerName;

  const PlayerSubscriptionHistoryScreen({
    super.key,
    required this.playerId,
    required this.academyId,
    required this.playerName,
  });

  @override
  ConsumerState<PlayerSubscriptionHistoryScreen> createState() =>
      _PlayerSubscriptionHistoryScreenState();
}

class _PlayerSubscriptionHistoryScreenState
    extends ConsumerState<PlayerSubscriptionHistoryScreen> {
  String? _selectedFilter; // null = all, 'active', 'expired'

  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirmDelete(
      BuildContext context, SubscriptionEntity subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('حذف الاشتراك'),
        content: const Text(AppStrings.deleteSubscriptionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final error = await ref
        .read(playerSubscriptionsProvider(widget.playerId).notifier)
        .deleteSubscription(subscription.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? AppStrings.subscriptionDeleted),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onFilterTap(String? status) {
    setState(() => _selectedFilter = status);
    ref
        .read(playerSubscriptionsProvider(widget.playerId).notifier)
        .filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;
    final isAcademyLevelSame =
        !isSuperAdmin && authState?.user?.academyId == widget.academyId;
    final canEdit = isSuperAdmin || isAcademyLevelSame;

    final subscriptionsAsync =
        ref.watch(playerSubscriptionsProvider(widget.playerId));

    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    final currencyLabel =
        ref.watch(academyCurrencyLabelProvider(widget.academyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.subscriptionHistory,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.playerName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: (_) => RenewSubscriptionScreen(
                      playerId: widget.playerId,
                      academyId: widget.academyId,
                      playerName: widget.playerName,
                    ),
                  ))
                  .then((_) => ref
                      .read(playerSubscriptionsProvider(widget.playerId).notifier)
                      .refresh()),
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.renewSubscription),
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
            )
          : null,
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),

          // List
          Expanded(
            child: subscriptionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64.sp, color: AppColors.error),
                      Gap(16.h),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Gap(16.h),
                      ElevatedButton.icon(
                        onPressed: () => ref
                            .read(playerSubscriptionsProvider(widget.playerId).notifier)
                            .refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (subscriptions) {
                if (subscriptions.isEmpty) {
                  return _buildEmptyState(context, canEdit);
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(playerSubscriptionsProvider(widget.playerId).notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    itemCount: subscriptions.length,
                    separatorBuilder: (_, __) => Gap(8.h),
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];
                      return _SubscriptionCard(
                        subscription: sub,
                        dateFormat: dateFormat,
                        currencyLabel: currencyLabel,
                        canEdit: canEdit,
                        onDelete: canEdit
                            ? () => _confirmDelete(context, sub)
                            : null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SubscriptionAttendanceScreen(
                              playerId: widget.playerId,
                              playerName: widget.playerName,
                              subscription: sub,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: AppStrings.allSubscriptions,
              selected: _selectedFilter == null,
              onTap: () => _onFilterTap(null),
            ),
            Gap(8.w),
            _FilterChip(
              label: AppStrings.activeSubscription,
              selected: _selectedFilter == 'active',
              onTap: () => _onFilterTap('active'),
              selectedColor: AppColors.success,
            ),
            Gap(8.w),
            _FilterChip(
              label: AppStrings.expiredSubscription,
              selected: _selectedFilter == 'expired',
              onTap: () => _onFilterTap('expired'),
              selectedColor: AppColors.grey500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool canEdit) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 80.sp,
              color: AppColors.grey300,
            ),
            Gap(16.h),
            Text(
              AppStrings.noSubscriptions,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
            if (canEdit) ...[
              Gap(24.h),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (_) => RenewSubscriptionScreen(
                        playerId: widget.playerId,
                        academyId: widget.academyId,
                        playerName: widget.playerName,
                      ),
                    ))
                    .then((_) => ref
                        .read(playerSubscriptionsProvider(widget.playerId).notifier)
                        .refresh()),
                icon: const Icon(Icons.add),
                label: const Text('إضافة اشتراك جديد'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Chip Widget
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.grey100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? color : AppColors.grey200,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subscription Card Widget
// ---------------------------------------------------------------------------

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionEntity subscription;
  final DateFormat dateFormat;
  final String currencyLabel;
  final bool canEdit;
  final VoidCallback? onDelete;

  /// فتح حضور وغياب فترة هذا الاشتراك مقسّماً بالشهور.
  final VoidCallback? onTap;

  const _SubscriptionCard({
    required this.subscription,
    required this.dateFormat,
    required this.currencyLabel,
    required this.canEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew =
        subscription.type == SubscriptionType.newSubscription;

    return GestureDetector(
      onTap: onTap,
      onLongPress: canEdit ? onDelete : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: type badge + status chip
              Row(
                children: [
                  // Type badge
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isNew
                          ? AppColors.successLight
                          : AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      subscription.typeLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isNew
                            ? AppColors.success
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Status chip
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: subscription.isActive
                          ? AppColors.successLight
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      subscription.statusLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: subscription.isActive
                            ? AppColors.success
                            : AppColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
              Gap(12.h),
              // Amount
              Row(
                children: [
                  Icon(Icons.monetization_on_outlined,
                      size: 18.sp, color: AppColors.primary),
                  Gap(6.w),
                  Text(
                    '${subscription.amount.toStringAsFixed(0)} $currencyLabel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                ],
              ),
              Gap(8.h),
              // Date range
              Row(
                children: [
                  Icon(Icons.date_range_outlined,
                      size: 16.sp, color: AppColors.grey500),
                  Gap(6.w),
                  Text(
                    '${dateFormat.format(subscription.startDate)} — ${dateFormat.format(subscription.endDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
              // Notes
              if (subscription.notes != null &&
                  subscription.notes!.isNotEmpty) ...[
                Gap(8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_outlined,
                        size: 16.sp, color: AppColors.grey400),
                    Gap(6.w),
                    Expanded(
                      child: Text(
                        subscription.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.grey500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (canEdit) ...[
                Gap(8.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'اضغط مطولاً للحذف',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
