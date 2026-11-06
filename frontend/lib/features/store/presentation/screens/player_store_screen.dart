import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/utils/currency_utils.dart';
import 'package:hurghada_winners/core/widgets/full_screen_image_viewer.dart';
import 'package:hurghada_winners/features/store/data/store_product.dart';
import 'package:hurghada_winners/features/store/data/store_service.dart';
import 'package:hurghada_winners/features/store/presentation/providers/store_providers.dart';
import 'package:hurghada_winners/features/store/presentation/widgets/product_card.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// متجر الأكاديمية — جهة اللاعب: تصفّح المنتجات بشكل متجر احترافي، والضغط على
/// "شراء" يسجّل الطلب ثم يفتح واتساب المتجر برسالة جاهزة. عرض فقط (لا تعديل).
class PlayerStoreScreen extends ConsumerWidget {
  const PlayerStoreScreen({super.key});

  StoreService get _service => sl<StoreService>();

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    StoreProduct product,
  ) async {
    final state = ref.read(playerStoreProvider);
    final messenger = ScaffoldMessenger.of(context);

    if (state.whatsApp.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('رقم واتساب المتجر غير متوفر حالياً'),
        backgroundColor: AppColors.error));
      return;
    }

    // 1) تسجيل الطلب في النظام (لا نُفشل الشراء لو تعذّر التسجيل الشبكي).
    try {
      await _service.createOrder(product.id);
    } catch (_) {/* نُكمل لفتح واتساب على أي حال */}

    // 2) فتح واتساب المتجر برسالة الشراء الجاهزة.
    final message = WhatsAppUtils.buyProductTemplate(
      academyName: state.academyName,
      productName: product.name,
      price: ProductCard.formatPrice(product.price),
      currency: CurrencyUtils.label(state.currency),
      playerName: null,
    );
    final ok = await WhatsAppUtils.open(state.whatsApp, message: message);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر فتح واتساب. تأكد من تثبيت التطبيق.'),
        backgroundColor: AppColors.error));
    }
  }

  void _openDetail(BuildContext context, WidgetRef ref, StoreProduct product) {
    final state = ref.read(playerStoreProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => _ProductDetailSheet(
        product: product,
        currencyCode: state.currency,
        onBuy: () {
          Navigator.pop(context);
          _buy(context, ref, product);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerStoreProvider);
    final notifier = ref.read(playerStoreProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المتجر'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: _body(context, ref, state, notifier),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    PlayerStoreState state,
    PlayerStoreNotifier notifier,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return _StoreMessage(
        icon: Icons.error_outline,
        color: AppColors.error,
        title: 'تعذّر تحميل المتجر',
        actionLabel: 'إعادة المحاولة',
        onAction: notifier.refresh,
      );
    }
    if (state.items.isEmpty) {
      return const _StoreMessage(
        icon: Icons.storefront_outlined,
        color: AppColors.grey400,
        title: 'لا توجد منتجات في المتجر بعد',
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
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 20.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.62,
          ),
          itemCount: state.items.length + (state.loadingMore ? 2 : 0),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final product = state.items[index];
            return ProductCard(
              product: product,
              currencyCode: state.currency,
              onTap: () => _openDetail(context, ref, product),
              actionButton: ElevatedButton.icon(
                onPressed: product.isAvailable
                    ? () => _buy(context, ref, product)
                    : null,
                icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                label: const Text('شراء'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  textStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ورقة تفاصيل المنتج (صورة كبيرة + وصف + سعر + زر شراء بارز).
class _ProductDetailSheet extends StatelessWidget {
  final StoreProduct product;
  final String currencyCode;
  final VoidCallback onBuy;

  const _ProductDetailSheet({
    required this.product,
    required this.currencyCode,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            // الضغط على الصورة يفتحها ملء الشاشة مع التكبير.
            GestureDetector(
              onTap: product.imageUrl.isEmpty
                  ? null
                  : () => showFullScreenImage(context, product.imageUrl),
              child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
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
            ),
            Gap(14.h),
            Text(product.name,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
            Gap(8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(ProductCard.formatPrice(product.price),
                    style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
                Gap(6.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 3.h),
                  child: Text(CurrencyUtils.label(currencyCode),
                      style: TextStyle(fontSize: 13.sp, color: AppColors.grey500)),
                ),
                const Spacer(),
                if (!product.isAvailable)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text('غير متاح حالياً',
                        style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            if (product.description.isNotEmpty) ...[
              Gap(14.h),
              Text(product.description,
                  style: TextStyle(
                      fontSize: 14.sp, color: AppColors.grey700, height: 1.5)),
            ],
            Gap(20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: product.isAvailable ? onBuy : null,
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('شراء عبر واتساب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _StoreMessage({
    required this.icon,
    required this.color,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 52.sp),
          Gap(14.h),
          Text(title,
              style: TextStyle(fontSize: 15.sp, color: AppColors.grey600)),
          if (actionLabel != null && onAction != null) ...[
            Gap(14.h),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
