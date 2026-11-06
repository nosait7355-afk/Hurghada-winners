import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// شاشة "طلبك قيد المراجعة" — تظهر للاعب المسجَّل ذاتياً طالما لم توافق
/// الأكاديمية على طلب انضمامه بعد (registrationStatus != 'approved').
/// لا تعرض أي محتوى من بوابة اللاعب — الباك إند أصلاً يحجب كل شيء غير /me.
class PlayerPendingApprovalScreen extends ConsumerWidget {
  const PlayerPendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider).valueOrNull;
    final player = session?.player;
    final fullName = player?['fullName'] as String? ?? '';
    final status = player?['registrationStatus'] as String? ?? 'pending';
    final rejectionReason = player?['rejectionReason'] as String?;
    final isRejected = status == 'rejected';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 440.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96.w,
                      height: 96.w,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                        color: AppColors.white,
                        size: 48.sp,
                      ),
                    ),
                    Gap(24.h),
                    Text(
                      isRejected ? 'تم رفض طلب انضمامك' : 'طلبك قيد المراجعة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.sp, fontWeight: FontWeight.w800, color: AppColors.white,
                      ),
                    ),
                    if (fullName.isNotEmpty) ...[
                      Gap(6.h),
                      Text(
                        fullName,
                        style: TextStyle(fontSize: 14.sp, color: AppColors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                    Gap(20.h),
                    Container(
                      padding: EdgeInsets.all(18.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Text(
                        isRejected
                            ? (rejectionReason?.isNotEmpty == true
                                ? rejectionReason!
                                : 'للأسف تم رفض طلب انضمامك من قِبل الأكاديمية. يرجى التواصل معها لمزيد من التفاصيل.')
                            : 'تم استلام طلب انضمامك بنجاح وسيقوم فريق الأكاديمية بمراجعته '
                              'قريباً. هتوصلك رسالة هنا بمجرد الموافقة على طلبك.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, height: 1.8, color: AppColors.grey700),
                      ),
                    ),
                    Gap(28.h),
                    SizedBox(
                      width: double.infinity,
                      height: 46.h,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(playerSessionProvider.notifier).logout();
                          if (context.mounted) context.go(AppRoutes.playerLogin);
                        },
                        icon: const Icon(Icons.logout, color: AppColors.white),
                        label: Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.white.withValues(alpha: 0.7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
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
