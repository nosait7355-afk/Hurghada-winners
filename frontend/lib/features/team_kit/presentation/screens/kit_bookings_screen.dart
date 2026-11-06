import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/widgets/confirm_delete_dialog.dart';
import 'package:hurghada_winners/core/utils/currency_utils.dart';
import 'package:hurghada_winners/features/store/presentation/widgets/product_card.dart';
import 'package:hurghada_winners/features/team_kit/data/kit_booking.dart';
import 'package:hurghada_winners/features/team_kit/data/team_kit.dart';
import 'package:hurghada_winners/features/team_kit/data/team_kit_service.dart';
import 'package:hurghada_winners/features/team_kit/presentation/dialogs/booking_review_dialog.dart';
import 'package:hurghada_winners/features/team_kit/presentation/dialogs/manager_add_booking_dialog.dart';
import 'package:hurghada_winners/features/team_kit/presentation/providers/team_kit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// سجل حجوزات طقم الفريق — جهة المدير: تبويب "بانتظار المراجعة" و"معتمدة"،
/// مع إمكانية تعديل بيانات الحجز وحالة الدفع قبل الموافقة/الرفض، وإضافة
/// حجز مباشرة للاعب.
class KitBookingsScreen extends ConsumerStatefulWidget {
  final String? academyId;
  const KitBookingsScreen({super.key, this.academyId});

  @override
  ConsumerState<KitBookingsScreen> createState() => _KitBookingsScreenState();
}

class _KitBookingsScreenState extends ConsumerState<KitBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  TeamKitService get _service => sl<TeamKitService>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) return;
        final status = _tabController.index == 0 ? 'pending_review' : 'approved';
        ref.read(kitBookingsProvider(widget.academyId).notifier).setFilter(status);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _review(KitBooking booking, List<String> sizes) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<BookingReviewResult>(
      context: context,
      builder: (_) => BookingReviewDialog(booking: booking, availableSizes: sizes),
    );
    if (res == null) return;
    try {
      await _service.reviewBooking(
        id: booking.id,
        size: res.size,
        paymentStatus: res.paymentStatus,
        paidAmount: res.paidAmount,
        status: res.status,
      );
      ref.read(kitBookingsProvider(widget.academyId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم تحديث الحجز بنجاح'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر تحديث الحجز.'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _delete(KitBooking booking) async {
    final ok = await confirmDelete(context,
        title: 'حذف الحجز',
        message: 'حذف حجز "${booking.playerName}" (مقاس ${booking.size}) نهائياً؟');
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.deleteBooking(booking.id);
      ref.read(kitBookingsProvider(widget.academyId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
          content: Text('تم حذف الحجز'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('تعذّر حذف الحجز.'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _addBooking(List<String> sizes) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<ManagerBookingResult>(
      context: context,
      builder: (_) => ManagerAddBookingDialog(availableSizes: sizes),
    );
    if (res == null) return;
    try {
      await _service.createManagerBooking(
        playerId: res.playerId,
        size: res.size,
        paymentStatus: res.paymentStatus,
        paidAmount: res.paidAmount,
        academyId: widget.academyId,
      );
      ref.read(kitBookingsProvider(widget.academyId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم إضافة الحجز بنجاح'), backgroundColor: AppColors.success));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e is AppException && e.message.trim().isNotEmpty
            ? e.message
            : 'تعذّرت الإضافة.'),
        backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kitState = ref.watch(teamKitProvider(widget.academyId));
    final sizes = kitState.kit?.availableSizes ?? const <String>[];
    final state = ref.watch(kitBookingsProvider(widget.academyId));
    final notifier = ref.read(kitBookingsProvider(widget.academyId).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حجوزات طقم الفريق'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'بانتظار المراجعة'),
            Tab(text: 'معتمدة'),
          ],
        ),
      ),
      floatingActionButton: sizes.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addBooking(sizes),
              icon: const Icon(Icons.add),
              label: const Text('إضافة حجز'),
            ),
      body: Column(
        children: [
          if (state.statusFilter == 'approved' && state.sizeCounts.isNotEmpty)
            _SizeFilterBar(
              counts: state.sizeCounts,
              selected: state.sizeFilter,
              onSelected: notifier.setSize,
            ),
          Expanded(child: _list(state, notifier, sizes)),
        ],
      ),
    );
  }

  Widget _list(KitBookingsState state, KitBookingsNotifier notifier, List<String> sizes) {
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
            const Text('تعذّر تحميل الحجوزات'),
            SizedBox(height: 12.h),
            ElevatedButton(onPressed: notifier.refresh, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 52.sp, color: AppColors.grey400),
            SizedBox(height: 12.h),
            Text('لا توجد حجوزات', style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
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
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 90.h),
          itemCount: state.items.length + (state.loadingMore ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final booking = state.items[index];
            return _BookingTile(
              booking: booking,
              onTap: sizes.isEmpty ? null : () => _review(booking, sizes),
              onDelete: () => _delete(booking),
            );
          },
        ),
      ),
    );
  }
}

/// فرز المعتمدة بالمقاس: "الكل" + كل مقاس محجوز مع عدده (بترتيب المقاسات).
class _SizeFilterBar extends StatelessWidget {
  final Map<String, int> counts;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _SizeFilterBar(
      {required this.counts, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final ordered = [
      for (final s in kKitSizes)
        if (counts.containsKey(s)) s,
    ];
    Widget chip(String label, String? value) {
      final isSel = selected == value;
      return Padding(
        padding: EdgeInsetsDirectional.only(end: 8.w),
        child: ChoiceChip(
          label: Text(label),
          selected: isSel,
          onSelected: (_) => onSelected(value),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSel ? AppColors.white : AppColors.grey700,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: AppColors.white,
        ),
      );
    }

    return SizedBox(
      height: 50.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        children: [
          chip('الكل ($total)', null),
          for (final s in ordered) chip('$s (${counts[s]})', s),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final KitBooking booking;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const _BookingTile({required this.booking, this.onTap, this.onDelete});

  static Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  static const _statusLabels = <String, String>{
    'pending_review': 'بانتظار المراجعة',
    'approved': 'معتمد',
    'rejected': 'مرفوض',
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    final dateStr = booking.createdAt != null
        ? DateFormat('yyyy/MM/dd — HH:mm', 'ar').format(booking.createdAt!.toLocal())
        : '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
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
                  child: Text(booking.playerName,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _statusLabels[booking.status] ?? booking.status,
                    style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.w700),
                  ),
                ),
                if (onDelete != null) DeleteIconButton(onPressed: onDelete, size: 20.sp),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'المقاس: ${booking.size}',
              style: TextStyle(fontSize: 13.sp, color: AppColors.grey700),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(
                  booking.paymentStatus == 'paid'
                      ? Icons.check_circle_outline
                      : Icons.hourglass_empty,
                  size: 14.sp,
                  color: booking.paymentStatus == 'paid' ? AppColors.success : AppColors.warning,
                ),
                SizedBox(width: 4.w),
                Text(
                  booking.paymentStatus == 'paid'
                      ? 'مدفوع (${ProductCard.formatPrice(booking.paidAmount)} ${CurrencyUtils.label(booking.currency)})'
                      : 'لم يدفع بعد',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey700),
                ),
                const Spacer(),
                Text(
                  '${ProductCard.formatPrice(booking.price)} ${CurrencyUtils.label(booking.currency)}',
                  style: TextStyle(
                      fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
            // مؤشّر الإيصال — يعرف المدير من القائمة إن كان الحجز مرفقاً
            // بإيصال قبل أن يفتحه للمراجعة.
            if (booking.hasReceipt) ...[
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 14.sp, color: AppColors.success),
                  SizedBox(width: 4.w),
                  Text('إيصال مرفق',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.success)),
                ],
              ),
            ],
            if (dateStr.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(dateStr, style: TextStyle(fontSize: 11.sp, color: AppColors.grey400)),
            ],
          ],
        ),
      ),
    );
  }
}
