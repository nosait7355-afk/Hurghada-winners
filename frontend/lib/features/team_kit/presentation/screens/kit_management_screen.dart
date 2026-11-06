import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/utils/currency_utils.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/currency_provider.dart';
import 'package:hurghada_winners/features/dashboard/presentation/providers/selected_academy_provider.dart';
import 'package:hurghada_winners/features/store/presentation/widgets/product_card.dart';
import 'package:hurghada_winners/features/team_kit/presentation/dialogs/kit_form_dialog.dart';
import 'package:hurghada_winners/features/team_kit/presentation/providers/team_kit_providers.dart';
import 'package:hurghada_winners/features/team_kit/presentation/screens/kit_bookings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// طقم الفريق — جهة المدير: عرض/إضافة/تعديل/حذف الطقم الفعّال للأكاديمية،
/// والوصول إلى سجل الحجوزات.
class KitManagementScreen extends ConsumerWidget {
  const KitManagementScreen({super.key});

  String _currencyLabel(WidgetRef ref) {
    final academyId = ref.read(effectiveAcademyIdProvider);
    return ref.read(academyCurrencyLabelProvider(academyId));
  }

  Future<void> _addOrEdit(BuildContext context, WidgetRef ref, KitState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final academyId = ref.read(effectiveAcademyIdProvider);
    final res = await showDialog<KitFormResult>(
      context: context,
      builder: (_) => KitFormDialog(existing: state.kit, currencyLabel: _currencyLabel(ref)),
    );
    if (res == null) return;
    try {
      await ref.read(teamKitProvider(academyId).notifier).save(
            imagePath: res.imagePath,
            name: res.name,
            price: res.price,
            availableSizes: res.availableSizes,
          );
      messenger.showSnackBar(const SnackBar(
        content: Text('تم حفظ طقم الفريق بنجاح'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر الحفظ. حاول مرة أخرى.'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final academyId = ref.read(effectiveAcademyIdProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('حذف طقم الفريق'),
        content: const Text('هل تريد حذف الطقم الحالي نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(teamKitProvider(academyId).notifier).deleteKit();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم حذف طقم الفريق'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر الحذف.'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyId = ref.watch(effectiveAcademyIdProvider);
    final state = ref.watch(teamKitProvider(academyId));
    final notifier = ref.read(teamKitProvider(academyId).notifier);
    final currencyCode = ref.watch(academyCurrencyCodeProvider(academyId));
    final pending = ref.watch(kitBookingsProvider(academyId)).pendingCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('طقم الفريق'),
        actions: [
          _BookingsButton(
            count: pending,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => KitBookingsScreen(academyId: academyId)),
            ),
          ),
        ],
      ),
      body: _body(context, ref, state, notifier, currencyCode),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    KitState state,
    KitNotifier notifier,
    String currencyCode,
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
            const Text('تعذّر تحميل بيانات الطقم'),
            SizedBox(height: 12.h),
            ElevatedButton(onPressed: notifier.refresh, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final kit = state.kit;
    if (kit == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom_outlined, size: 52.sp, color: AppColors.grey400),
            SizedBox(height: 12.h),
            Text('لم يُضَف طقم الفريق بعد',
                style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _addOrEdit(context, ref, state),
              icon: const Icon(Icons.add),
              label: const Text('إضافة طقم الفريق'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: CachedNetworkImage(
                imageUrl: kit.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.grey100),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.grey100,
                  child: Icon(Icons.image_not_supported_outlined,
                      color: AppColors.grey400, size: 40.sp),
                ),
              ),
            ),
          ),
          Gap(14.h),
          Text(kit.name, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
          Gap(6.h),
          Row(
            children: [
              Text(ProductCard.formatPrice(kit.price),
                  style: TextStyle(
                      fontSize: 20.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
              Gap(6.w),
              Text(CurrencyUtils.label(currencyCode),
                  style: TextStyle(fontSize: 13.sp, color: AppColors.grey500)),
            ],
          ),
          Gap(14.h),
          Text('المقاسات المتاحة', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
          Gap(8.h),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kit.availableSizes
                .map((s) => Chip(label: Text(s), backgroundColor: AppColors.grey100))
                .toList(),
          ),
          Gap(20.h),
          ElevatedButton.icon(
            onPressed: () => _addOrEdit(context, ref, state),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('تعديل الطقم'),
          ),
          Gap(10.h),
          OutlinedButton.icon(
            onPressed: () => _delete(context, ref),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('حذف الطقم'),
          ),
        ],
      ),
    );
  }
}

class _BookingsButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _BookingsButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'الحجوزات',
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
