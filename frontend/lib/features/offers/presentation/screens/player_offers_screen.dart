import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/offers/presentation/providers/offers_providers.dart';
import 'package:hurghada_winners/features/offers/presentation/widgets/offer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// العروض والخصومات السارية لفرع اللاعب.
class PlayerOffersScreen extends ConsumerWidget {
  const PlayerOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerOffersProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('العروض والخصومات'), centerTitle: true),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(playerOffersProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ),
        data: (offers) => offers.isEmpty
            ? Center(
                child: Text('لا توجد عروض حالياً',
                    style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(playerOffersProvider),
                child: ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => Gap(12.h),
                  itemBuilder: (_, i) => OfferCard(offer: offers[i]),
                ),
              ),
      ),
    );
  }
}
