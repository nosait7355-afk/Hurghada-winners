import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/offers/presentation/providers/offers_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// شريط العروض السارية في لوحة اللاعب — لا يظهر إن لم توجد عروض.
class PlayerOffersStrip extends ConsumerWidget {
  const PlayerOffersStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(playerOffersProvider).valueOrNull ?? const [];
    if (offers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: AppColors.error, size: 20.sp),
              Gap(6.w),
              Text('العروض والخصومات',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(AppRoutes.playerOffers),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          SizedBox(
            height: 120.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: offers.length,
              separatorBuilder: (_, __) => Gap(10.w),
              itemBuilder: (_, i) {
                final o = offers[i];
                final hasImage = o.imageUrl != null && o.imageUrl!.isNotEmpty;
                final discount = o.discountLabel;
                return InkWell(
                  onTap: () => context.push(AppRoutes.playerOffers),
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    width: 240.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      gradient: const LinearGradient(
                        colors: [AppColors.error, AppColors.primary],
                      ),
                      image: hasImage
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(o.imageUrl!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.45),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                    ),
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (discount != null)
                          Text(discount,
                              style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900)),
                        Text(o.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
