import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/utils/currency_utils.dart';
import 'package:hurghada_winners/core/widgets/confirm_delete_dialog.dart';
import 'package:hurghada_winners/features/store/data/store_order.dart';
import 'package:hurghada_winners/features/store/presentation/providers/store_providers.dart';
import 'package:hurghada_winners/features/store/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// طلبات المتجر — جهة المدير: قائمة طلبات اللاعبين مع تصفية بالحالة وتحديثها.
class StoreOrdersScreen extends ConsumerWidget {
  final String? academyId;
  const StoreOrdersScreen({super.key, this.academyId});

  static const _statuses = <String, String>{
    'pending': 'جديد',
    'contacted': 'تم التواصل',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
  };

  static Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return AppColors.success;
      case 'contacted':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.grey500;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeOrdersProvider(academyId));
    final notifier = ref.read(storeOrdersProvider(academyId).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('طلبات المتجر')),
      body: Column(
        children: [
          _FilterBar(
            selected: state.statusFilter,
            onSelect: notifier.setFilter,
          ),
          Expanded(child: _list(context, ref, state, notifier)),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    OrdersState state,
    OrdersNotifier notifier,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            SizedBox(height: 12.h),
            const Text('تعذّر تحميل الطلبات'),
            SizedBox(height: 12.h),
            ElevatedButton(
                onPressed: notifier.refresh,
                child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 52.sp, color: AppColors.grey400),
            SizedBox(height: 12.h),
            Text('لا توجد طلبات',
                style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
            notifier.loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 20.h),
          itemCount: state.items.length + (state.loadingMore ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return _OrderTile(
              order: state.items[index],
              onChangeStatus: (s) =>
                  notifier.updateStatus(state.items[index].id, s),
              onDelete: () async {
                final o = state.items[index];
                final ok = await confirmDelete(context,
                    title: 'حذف الطلب',
                    message: 'حذف طلب "${o.playerName}" نهائياً؟');
                if (!ok) return;
                try {
                  await notifier.deleteOrder(o.id);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تعذّر حذف الطلب'),
                        backgroundColor: AppColors.error));
                  }
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? selected;
  final void Function(String?) onSelect;
  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final entries = [
      const MapEntry<String?, String>(null, 'الكل'),
      ...StoreOrdersScreen._statuses.entries
          .map((e) => MapEntry<String?, String>(e.key, e.value)),
    ];
    return SizedBox(
      height: 52.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        itemCount: entries.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final e = entries[i];
          final active = selected == e.key;
          return ChoiceChip(
            label: Text(e.value),
            selected: active,
            onSelected: (_) => onSelect(e.key),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: active ? AppColors.white : AppColors.grey700,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final StoreOrder order;
  final void Function(String) onChangeStatus;
  final VoidCallback onDelete;
  const _OrderTile(
      {required this.order,
      required this.onChangeStatus,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = StoreOrdersScreen._statusColor(order.status);
    final dateStr = order.createdAt != null
        ? DateFormat('yyyy/MM/dd — HH:mm', 'ar')
            .format(order.createdAt!.toLocal())
        : '';
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.productName,
                    style: TextStyle(
                        fontSize: 15.sp, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  StoreOrdersScreen._statuses[order.status] ?? order.status,
                  style: TextStyle(
                      color: color,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.person_outline, size: 15.sp, color: AppColors.grey500),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  // اسم فرع اللاعب — يظهر للحساب الرئيسي (طلبات كل الفروع).
                  order.academyName.isNotEmpty
                      ? '${order.playerName} — ${order.academyName}'
                      : order.playerName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.grey700),
                ),
              ),
              const Spacer(),
              Text(
                '${ProductCard.formatPrice(order.price)} ${CurrencyUtils.label(order.currency)}',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
            ],
          ),
          if (dateStr.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(dateStr,
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey400)),
          ],
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DeleteIconButton(onPressed: onDelete, size: 20.sp),
              PopupMenuButton<String>(
                onSelected: onChangeStatus,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 14.sp, color: AppColors.grey700),
                      SizedBox(width: 4.w),
                      Text('تغيير الحالة',
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.grey700)),
                    ],
                  ),
                ),
                itemBuilder: (_) => StoreOrdersScreen._statuses.entries
                    .map((e) =>
                        PopupMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
