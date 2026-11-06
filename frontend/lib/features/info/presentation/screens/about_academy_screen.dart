import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// شاشة "نبذة عن الأكاديمية" — تعرض وصف الأكاديمية بالكامل بالإضافة إلى
/// معرض صور يتم تصفحه أفقياً بشكل احترافي (سكرول مع تكبير الصورة النشطة).
class AboutAcademyScreen extends StatefulWidget {
  const AboutAcademyScreen({super.key});

  @override
  State<AboutAcademyScreen> createState() => _AboutAcademyScreenState();
}

class _AboutAcademyScreenState extends State<AboutAcademyScreen> {
  late final PageController _pageController;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78)
      ..addListener(() {
        setState(() => _page = _pageController.page ?? 0);
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 22.sp),
                    Gap(6.w),
                    Text(
                      'نبذة عن الأكاديمية',
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Text(
                            AppConstants.aboutAcademyText,
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              height: 1.9,
                              color: AppColors.grey800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Gap(28.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library_outlined,
                                color: AppColors.white, size: 20.sp),
                            Gap(8.w),
                            Text(
                              'صور من الأكاديمية',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap(14.h),
                      SizedBox(
                        height: 260.h,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: AppConstants.aboutGalleryImageCount,
                          padEnds: true,
                          itemBuilder: (context, index) {
                            final diff = (_page - index).abs();
                            final scale = (1 - (diff * 0.15)).clamp(0.85, 1.0);
                            final opacity =
                                (1 - (diff * 0.4)).clamp(0.5, 1.0);
                            return Center(
                              child: Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(20.r),
                                      child: Image.asset(
                                        'assets/images/about/about_${(index + 1).toString().padLeft(2, '0')}.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          color: AppColors.grey200,
                                          child: const Icon(
                                              Icons.image_not_supported,
                                              color: AppColors.grey400),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Gap(12.h),
                      Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: AppConstants.aboutGalleryImageCount,
                        ),
                      ),
                      Gap(24.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مؤشر نقاط بسيط يتبع صفحة الـ PageView الحالية بدون الاعتماد على حزمة خارجية.
class SmoothPageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;

  const SmoothPageIndicator(
      {super.key, required this.controller, required this.count});

  @override
  Widget build(BuildContext context) {
    final page = controller.hasClients ? (controller.page ?? 0) : 0.0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      children: List.generate(count, (i) {
        final active = (page - i).abs() < 0.5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
