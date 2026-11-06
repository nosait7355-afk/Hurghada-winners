import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/utils/currency_utils.dart';
import 'package:hurghada_winners/features/store/data/store_product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// بطاقة منتج بشكل متجر احترافي: صورة كبيرة، شارة سعر، حالة توفّر، زر إجراء.
/// تُستخدم في شبكة اللاعب (زر شراء) وشبكة المدير (قائمة تعديل/حذف).
class ProductCard extends StatelessWidget {
  final StoreProduct product;
  final String currencyCode;
  final VoidCallback? onTap;

  /// زر الإجراء أسفل البطاقة (شراء للاعب). إن كان null لا يظهر.
  final Widget? actionButton;

  /// قائمة منبثقة أعلى الصورة (تعديل/حذف للمدير). إن كانت null لا تظهر.
  final Widget? cornerMenu;

  const ProductCard({
    super.key,
    required this.product,
    required this.currencyCode,
    this.onTap,
    this.actionButton,
    this.cornerMenu,
  });

  static String formatPrice(double price) {
    // بلا كسور إن كان رقماً صحيحاً، وإلا خانتان عشريتان.
    final isWhole = price == price.roundToDouble();
    return NumberFormat(isWhole ? '#,##0' : '#,##0.00', 'ar').format(price);
  }

  @override
  Widget build(BuildContext context) {
    final available = product.isAvailable;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── الصورة + الشارات ──
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter: available
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.grey100,
                          child: Center(
                            child: SizedBox(
                              width: 22.r,
                              height: 22.r,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.grey100,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: AppColors.grey400, size: 34.sp),
                        ),
                      ),
                    ),
                    if (!available)
                      Positioned(
                        top: 8.r,
                        left: 8.r,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text('غير متاح',
                              style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (cornerMenu != null)
                      Positioned(top: 4.r, right: 4.r, child: cornerMenu!),
                  ],
                ),
              ),
              // ── الاسم + السعر ──
              Padding(
                padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: AppColors.grey900),
                    ),
                    Gap(6.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(product.price),
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary),
                        ),
                        Gap(4.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            CurrencyUtils.label(currencyCode),
                            style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (actionButton != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
                  child: SizedBox(width: double.infinity, child: actionButton),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
