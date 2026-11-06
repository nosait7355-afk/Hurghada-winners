import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/services/pwa/pwa_install.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// زر "تثبيت التطبيق على الجهاز".
///
/// يختفي تماماً (SizedBox.shrink) خارج المتصفح، وحين يكون التطبيق مثبَّتاً
/// بالفعل — ولا يشغل مساحة ولا يترك فراغاً في التخطيط في الحالتين.
///
/// الضغط يفتح نافذة التثبيت إن أتاحها المتصفح، وإلّا يعرض الخطوات اليدوية.
/// انظر [PwaInstall.canInstall] لسبب عدم اشتراط حدث المتصفح للظهور.
class InstallAppButton extends StatefulWidget {
  /// لون النص والحد — الشاشات ذات الخلفية الداكنة تمرّر الأبيض.
  final Color color;

  const InstallAppButton({super.key, this.color = AppColors.white});

  @override
  State<InstallAppButton> createState() => _InstallAppButtonState();
}

class _InstallAppButtonState extends State<InstallAppButton> {
  @override
  void initState() {
    super.initState();
    // beforeinstallprompt قد يصل بعد أول بناء بثوانٍ، فنعيد البناء عند وصوله.
    PwaInstall.addListener(_onChanged);
  }

  @override
  void dispose() {
    PwaInstall.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _install() async {
    if (PwaInstall.needsManualIosSteps) {
      await _showManualSteps();
      return;
    }
    await PwaInstall.promptInstall();
  }

  /// يُعرض حين لا يمكن فتح نافذة التثبيت برمجياً: على iOS دائماً، وعلى بقية
  /// المتصفحات بعد استهلاك حدث التثبيت (من فتح النافذة وأغلقها).
  Future<void> _showManualSteps() {
    final ios = PwaInstall.isIosBrowser;
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تثبيت التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ios ? 'من متصفح Safari:' : 'من قائمة المتصفح:',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10.h),
            if (ios) ...[
              _step(1, 'اضغط زر المشاركة في شريط المتصفح', Icons.ios_share),
              _step(2, 'اختر «إضافة إلى الشاشة الرئيسية»',
                  Icons.add_box_outlined),
              _step(3, 'اضغط «إضافة»', Icons.check_circle_outline),
            ] else ...[
              _step(1, 'افتح قائمة المتصفح (⋮)', Icons.more_vert),
              _step(2, 'اختر «تثبيت التطبيق» أو «إضافة إلى الشاشة الرئيسية»',
                  Icons.install_mobile_outlined),
              _step(3, 'اضغط «تثبيت»', Icons.check_circle_outline),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  Widget _step(int n, String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primary),
          SizedBox(width: 8.w),
          Expanded(
            child: Text('$n. $text', style: TextStyle(fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!PwaInstall.canInstall) return const SizedBox.shrink();

    // المسافة العلوية داخل الودجت لا خارجها، وإلا بقي فراغ معلّق في التخطيط
    // حين يختفي الزر.
    return Padding(
      padding: EdgeInsets.only(top: 18.h),
      child: OutlinedButton.icon(
        onPressed: _install,
        icon: Icon(Icons.install_mobile_outlined,
            size: 18.sp, color: widget.color),
        label: Text(
          'تثبيت التطبيق على الجهاز',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: widget.color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: widget.color.withValues(alpha: 0.7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }
}
