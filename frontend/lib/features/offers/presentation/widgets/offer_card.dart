import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/widgets/full_screen_image_viewer.dart';
import 'package:hurghada_winners/features/offers/data/offer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// كارت عرض/خصم — صورة (اختيارية) + شارة الخصم + العنوان والتفاصيل والمدة.
/// [footer] عناصر إضافية للإدارة (الفروع، الحالة، أزرار التعديل).
class OfferCard extends StatelessWidget {
  final Offer offer;
  final Widget? footer;
  final bool compactDetails;

  const OfferCard({
    super.key,
    required this.offer,
    this.footer,
    this.compactDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'ar');
    final discount = offer.discountLabel;
    final hasImage = offer.imageUrl != null && offer.imageUrl!.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage)
            GestureDetector(
              onTap: () => showFullScreenImage(context, offer.imageUrl!),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: offer.imageUrl!, fit: BoxFit.cover),
                    if (discount != null)
                      PositionedDirectional(
                        top: 10,
                        start: 10,
                        child: _DiscountBadge(text: discount),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer_outlined,
                        color: AppColors.primary, size: 20.sp),
                    Gap(6.w),
                    Expanded(
                      child: Text(offer.title,
                          style: TextStyle(
                              fontSize: 15.sp, fontWeight: FontWeight.w800)),
                    ),
                    if (!hasImage && discount != null)
                      _DiscountBadge(text: discount),
                  ],
                ),
                if (offer.details.isNotEmpty) ...[
                  Gap(6.h),
                  Text(
                    offer.details,
                    maxLines: compactDetails ? 3 : null,
                    overflow: compactDetails ? TextOverflow.ellipsis : null,
                    style: TextStyle(fontSize: 13.sp, color: AppColors.grey700),
                  ),
                ],
                Gap(8.h),
                Text(
                  'من ${fmt.format(offer.startDate)} حتى ${fmt.format(offer.endDate)}',
                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey500),
                ),
                if (footer != null) ...[Gap(8.h), footer!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final String text;
  const _DiscountBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(text,
          style: TextStyle(
              color: AppColors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800)),
    );
  }
}
