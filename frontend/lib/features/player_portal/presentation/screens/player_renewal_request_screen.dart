import 'dart:typed_data';

import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/player_portal/data/player_api_service.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

/// طلب تجديد الاشتراك من بوابة اللاعب: صورة الإيصال (معرض أو كاميرا)
/// + ملاحظة اختيارية، ويُرسل للسوبر أدمن للمراجعة.
class PlayerRenewalRequestScreen extends ConsumerStatefulWidget {
  const PlayerRenewalRequestScreen({super.key});

  @override
  ConsumerState<PlayerRenewalRequestScreen> createState() =>
      _PlayerRenewalRequestScreenState();
}

class _PlayerRenewalRequestScreenState
    extends ConsumerState<PlayerRenewalRequestScreen> {
  final _noteCtrl = TextEditingController();
  XFile? _receipt;
  Uint8List? _preview;
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final img = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (img == null) return;
    // الصور الأكبر من 2MB تُصغَّر تلقائياً عند الرفع (buildImageMultipart).
    // bytes بدل File حتى تعمل المعاينة على الويب والموبايل.
    final bytes = await img.readAsBytes();
    if (!mounted) return;
    setState(() {
      _error = null;
      _receipt = img;
      _preview = bytes;
    });
  }

  Future<void> _submit() async {
    if (_receipt == null) {
      setState(() => _error = 'صورة إيصال الدفع مطلوبة');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sl<PlayerApiService>().submitRenewalRequest(
        receiptPath: _receipt!.path,
        note: _noteCtrl.text.trim(),
      );
      ref.invalidate(playerDashboardProvider);
      messenger.showSnackBar(const SnackBar(
        content: Text('تم إرسال طلب التجديد، بانتظار مراجعة الإدارة'),
        backgroundColor: AppColors.success,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      final serverMsg = e is DioException
          ? (e.response?.data is Map ? e.response?.data['message'] as String? : null)
          : null;
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = serverMsg ?? 'تعذّر إرسال الطلب. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تجديد الاشتراك')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            Text(
              'حوّل قيمة الاشتراك ثم ارفع صورة الإيصال، وستراجع الإدارة طلبك وتجدد اشتراكك.',
              style: TextStyle(fontSize: 13.sp, color: AppColors.grey700),
            ),
            Gap(16.h),
            Container(
              height: 260.h,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.grey200),
              ),
              clipBehavior: Clip.antiAlias,
              child: _preview != null
                  ? Image.memory(_preview!, fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48.sp, color: AppColors.grey400),
                        Gap(8.h),
                        Text('لم يتم اختيار صورة الإيصال',
                            style: TextStyle(
                                fontSize: 13.sp, color: AppColors.grey500)),
                      ],
                    ),
            ),
            Gap(12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('من المعرض'),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('تصوير بالكاميرا'),
                  ),
                ),
              ],
            ),
            Gap(16.h),
            TextField(
              controller: _noteCtrl,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              Gap(8.h),
              Text(_error!,
                  style: TextStyle(color: AppColors.error, fontSize: 13.sp)),
            ],
            Gap(16.h),
            SizedBox(
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('إرسال طلب التجديد'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
