import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة "فروعنا وملاعبنا" — تعرض كل فروع الأكاديمية مع رابط خرائط جوجل
/// لكل فرع. تُفتح من شاشة تسجيل الدخول وتحتوي على زر رجوع.
class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  Future<void> _openMap(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondary, AppColors.secondaryDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.login),
                      icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    ),
                    Gap(4.w),
                    Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 22.sp),
                    Gap(6.w),
                    Text(
                      'فروعنا وملاعبنا',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(20.r),
                  itemCount: AppConstants.branches.length,
                  separatorBuilder: (_, __) => Gap(16.h),
                  itemBuilder: (context, index) {
                    final branch = AppConstants.branches[index];
                    return _BranchCard(
                      branch: branch,
                      onTap: () => _openMap(context, branch.mapsUrl),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchInfo branch;
  final VoidCallback onTap;

  const _BranchCard({required this.branch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18.r),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(18.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.sports_soccer,
                    color: AppColors.primary, size: 26.sp),
              ),
              Gap(14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    Gap(6.h),
                    Text(
                      branch.description,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        color: AppColors.grey600,
                        height: 1.5,
                      ),
                    ),
                    Gap(10.h),
                    Row(
                      children: [
                        Icon(Icons.map_outlined,
                            size: 16.sp, color: AppColors.primary),
                        Gap(4.w),
                        Text(
                          'اضغط لفتح الموقع على الخريطة',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
