import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/offers/data/offer.dart';
import 'package:hurghada_winners/features/offers/data/offers_service.dart';
import 'package:hurghada_winners/features/offers/presentation/providers/offers_providers.dart';
import 'package:hurghada_winners/features/offers/presentation/screens/offer_form_screen.dart';
import 'package:hurghada_winners/features/offers/presentation/widgets/offer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// العروض والخصومات — جهة الإدارة.
class OffersManagementScreen extends ConsumerWidget {
  const OffersManagementScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, [Offer? offer]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OfferFormScreen(existing: offer)),
    );
    if (saved == true) {
      ref.invalidate(adminOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(offer == null
              ? 'تمت إضافة العرض وإشعار اللاعبين'
              : 'تم تحديث العرض'),
          backgroundColor: AppColors.success,
        ));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Offer offer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العرض'),
        content: Text('حذف "${offer.title}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await sl<OffersService>().delete(offer.id);
      ref.invalidate(adminOffersProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذّر حذف العرض'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    // الإضافة: الحساب الرئيسي ومدير الفرع (المشرف المحدود يعرض فقط).
    final canAdd = user?.isSuperAdmin == true || user?.isAcademyAdmin == true;
    final async = ref.watch(adminOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('العروض والخصومات'), centerTitle: true),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('إضافة عرض'),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(adminOffersProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ),
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 56.sp, color: AppColors.grey300),
                  Gap(12.h),
                  Text('لا توجد عروض بعد',
                      style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminOffersProvider),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 90.h),
              itemCount: offers.length,
              separatorBuilder: (_, __) => Gap(12.h),
              itemBuilder: (_, i) {
                final o = offers[i];
                return OfferCard(
                  offer: o,
                  compactDetails: true,
                  footer: _AdminFooter(
                    offer: o,
                    onEdit: o.canEdit ? () => _openForm(context, ref, o) : null,
                    onDelete: o.canEdit ? () => _delete(context, ref, o) : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminFooter extends StatelessWidget {
  final Offer offer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _AdminFooter({required this.offer, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = offer.isEnded
        ? ('انتهى', AppColors.grey500)
        : offer.isRunning
            ? ('ساري', AppColors.success)
            : !offer.isActive
                ? ('موقوف', AppColors.grey500)
                : ('لم يبدأ بعد', AppColors.warning);
    final branches = offer.forAllBranches
        ? 'كل الفروع'
        : offer.academyNames.where((n) => n.isNotEmpty).join('، ');

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(statusText,
              style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: statusColor)),
        ),
        Gap(8.w),
        Expanded(
          child: Text(branches,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5.sp, color: AppColors.primary)),
        ),
        if (onEdit != null)
          IconButton(
            tooltip: 'تعديل',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        if (onDelete != null)
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
          ),
      ],
    );
  }
}
