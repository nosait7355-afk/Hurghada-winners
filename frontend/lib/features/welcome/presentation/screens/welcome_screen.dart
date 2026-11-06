import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/core/widgets/info_link_button.dart';
import 'package:hurghada_winners/core/widgets/install_app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// شاشة الترحيب الرئيسية لمنصة Hurghada Winners. مساران:
/// 1) مدير أكاديمية: تسجيل دخول.
/// 2) لاعب / ولي أمر: تسجيل دخول.
/// وفوقهم زرّي "الفروع" و"نبذة عن الأكاديمية" (معلومات عامة بدون حاجة لتسجيل دخول).
/// تعمل بنفس الكود على Android / Windows / Flutter Web.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 460.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زرّي "الفروع" و"نبذة عن الأكاديمية" — كل واحد يفتح شاشة
                    // مستقلة بزر رجوع. موضوعين أعلى الشاشة عشان يكونوا أول
                    // حاجة يشوفها الزائر قبل اختيار مسار الدخول.
                    Row(
                      children: [
                        Expanded(
                          child: InfoLinkButton(
                            icon: Icons.location_on_outlined,
                            label: 'الفروع',
                            onTap: () => context.push(AppRoutes.branches),
                          ),
                        ),
                        Gap(12.w),
                        Expanded(
                          child: InfoLinkButton(
                            icon: Icons.info_outline,
                            label: 'نبذة عن الأكاديمية',
                            onTap: () => context.push(AppRoutes.aboutAcademy),
                          ),
                        ),
                      ],
                    ),
                    Gap(20.h),
                    // شعار التطبيق الرسمي داخل بطاقة بيضاء (الشعار يحمل الاسم
                    // بنفسه، فلا نكرّر كتابة Hurghada Winners تحته).
                    Container(
                      width: 132.w,
                      height: 132.w,
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(26.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo2026.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Gap(16.h),
                    Text(
                      'مرحباً بك',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    Gap(40.h),

                    // ── بطاقة مدير الأكاديمية ──
                    _RoleCard(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'دخول مدير أكاديمية',
                      children: [
                        _PrimaryButton(
                          label: 'تسجيل الدخول',
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                      ],
                    ),
                    Gap(18.h),

                    // ── بطاقة اللاعب / ولي الأمر ──
                    _RoleCard(
                      icon: Icons.person_outline,
                      title: 'دخول اللاعب / ولي الأمر',
                      children: [
                        _PrimaryButton(
                          label: 'تسجيل الدخول',
                          onPressed: () => context.go(AppRoutes.playerLogin),
                        ),
                      ],
                    ),

                    // يظهر على المتصفح فقط، ويختفي بعد التثبيت.
                    const InstallAppButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _RoleCard(
      {required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 26.sp),
              Gap(10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          Gap(16.h),
          ...children,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 50.h),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
