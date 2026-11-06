import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

/// نافذة تعرض بيانات دخول اللاعب المُنشأ (username/password) مرة واحدة
/// مع زرّي نسخ ومشاركة.
class PlayerAccountDialog {
  PlayerAccountDialog._();

  static Future<void> show(
    BuildContext context, {
    required String username,
    required String password,
    String playerName = '',
  }) async {
    final text = 'بيانات دخول اللاعب${playerName.isNotEmpty ? ' $playerName' : ''} '
        'على تطبيق Hurghada Winners:\n'
        'اسم المستخدم: $username\n'
        'كلمة المرور: $password';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            Gap(8.w),
            const Expanded(child: Text('تم إنشاء حساب اللاعب')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('اسم المستخدم', username),
            Gap(10.h),
            _row('كلمة المرور', password),
            Gap(12.h),
            Text('احفظ هذه البيانات — لن تظهر كلمة المرور مرة أخرى.',
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('تم نسخ البيانات')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('نسخ البيانات'),
          ),
          TextButton.icon(
            onPressed: () => Share.share(text),
            icon: const Icon(Icons.share),
            label: const Text('مشاركة'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
          Gap(4.h),
          SelectableText(value,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
              textDirection: TextDirection.ltr),
        ],
      ),
    );
  }
}
