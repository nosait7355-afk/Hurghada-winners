import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/attendance/domain/entities/attendance_entity.dart';
import 'package:hurghada_winners/features/attendance/domain/usecases/record_attendance_usecase.dart';
import 'package:hurghada_winners/features/attendance/presentation/widgets/attendance_kind_badge.dart';
import 'package:hurghada_winners/features/attendance/presentation/widgets/subscription_stats_banner.dart';
import 'package:hurghada_winners/features/attendance/presentation/widgets/web_qr_scanner.dart';
import 'package:hurghada_winners/features/attendance/utils/player_qr.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_detail_screen.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/renew_subscription_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class AttendanceScanScreen extends StatefulWidget {
  final String academyId;
  const AttendanceScanScreen({super.key, required this.academyId});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

/// اختيار المستخدم في حوار "اشتراك اللاعب منتهي".
enum _ExpiredChoice { renew, payLater, makeup, free }

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  // الكاميرا تُستخدم على Android والويب؛ على Windows نعتمد على إدخال يدوي/قارئ USB.
  // نستخدم defaultTargetPlatform لا Platform لأن dart:io غير متاحة على الويب.
  final bool _canUseCamera =
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  final TextEditingController _manualController = TextEditingController();
  final FocusNode _manualFocus = FocusNode();

  bool _processing = false;
  String? _lastCode;
  DateTime? _lastAt;
  AttendanceRecordResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!_canUseCamera) {
      // تركيز تلقائي ليستقبل قارئ USB (يكتب الكود + Enter).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _manualFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    _manualFocus.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }

  String _nowTimeStr() {
    final d = DateTime.now();
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  Future<void> _scanWithCamera() async {
    if (kIsWeb) {
      try {
        final code = await showWebQrScanner(context);
        if (code != null && code.trim().isNotEmpty) {
          await _handleCode(code);
        }
      } catch (e) {
        debugPrint('[ATTENDANCE] web camera scan threw: $e');
        if (!mounted) return;
        setState(() {
          _error = 'تعذّر فتح الكاميرا — استخدم الإدخال اليدوي';
        });
      }
      return;
    }
    try {
      final result = await BarcodeScanner.scan();
      debugPrint(
          '[ATTENDANCE] camera scan returned: type=${result.type} rawContent="${result.rawContent}"');
      if (result.type == ResultType.Barcode &&
          result.rawContent.trim().isNotEmpty) {
        await _handleCode(result.rawContent);
      } else if (result.type == ResultType.Error) {
        if (mounted) {
          setState(() => _error = 'تعذّر قراءة الكود، حاول مرة أخرى');
        }
      }
      // ResultType.Cancelled → المستخدم أغلق الماسح، لا شيء.
    } catch (e) {
      debugPrint('[ATTENDANCE] camera scan threw: $e');
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر فتح الكاميرا — استخدم الإدخال اليدوي';
      });
    }
  }

  Future<void> _handleCode(String raw) async {
    final code = PlayerQr.extractCode(raw);
    debugPrint('[ATTENDANCE] raw="$raw" → code="$code"');
    if (code.isEmpty || _processing) return;

    // منع تكرار الطلب لنفس الكود خلال 3 ثوانٍ (حماية ضد المسح المتكرر السريع / 429).
    if (_lastCode == code &&
        _lastAt != null &&
        DateTime.now().difference(_lastAt!).inSeconds < 3) {
      return;
    }
    _lastCode = code;
    _lastAt = DateTime.now();

    await _submit(code);

    // إعادة تجهيز حقل الإدخال اليدوي للمسحة التالية.
    if (mounted && !_canUseCamera) {
      _manualController.clear();
      _manualFocus.requestFocus();
    }
  }

  /// مسحة واحدة = طلب واحد. اشتراك منتهٍ بلا [mode] ⇒ حوار الخيارات ثم
  /// إعادة الإرسال بالنوع المختار.
  Future<void> _submit(String code, {AttendanceKind? mode}) async {
    setState(() {
      _processing = true;
      _error = null;
    });

    final result = await sl<RecordAttendanceUsecase>()(
      RecordAttendanceParams(
        code: code,
        localDate: _todayStr(),
        localTime: _nowTimeStr(),
        mode: mode,
      ),
    );
    if (!mounted) return;

    AttendanceRecordResult? res;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _result = null;
        _processing = false;
      }),
      (r) => res = r,
    );
    final r = res;
    if (r == null) return;

    if (r.subscriptionExpired && mode != null) {
      // الخادم تجاهل النوع — نسخة قديمة لا تدعم الخيارات.
      setState(() {
        _error = 'السيرفر يحتاج تحديثاً لتسجيل حضور لاعب منتهي الاشتراك';
        _result = null;
        _processing = false;
      });
      return;
    }
    if (r.subscriptionExpired) {
      setState(() {
        _processing = false;
        _result = null;
      });
      await _onExpired(code, r);
      return;
    }
    setState(() {
      _result = r;
      _processing = false;
    });
  }

  Future<void> _onExpired(String code, AttendanceRecordResult r) async {
    final choice = await showDialog<_ExpiredChoice>(
      context: context,
      builder: (_) => _ExpiredDialog(result: r),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _ExpiredChoice.renew:
        // التجديد لا يسجّل حضوراً — يفتح شاشة التجديد فقط.
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RenewSubscriptionScreen(
            playerId: r.player.id,
            academyId: widget.academyId,
            playerName: r.player.fullName,
          ),
        ));
      case _ExpiredChoice.payLater:
        await _submit(code, mode: AttendanceKind.payLater);
      case _ExpiredChoice.makeup:
        await _submit(code, mode: AttendanceKind.makeup);
      case _ExpiredChoice.free:
        await _submit(code, mode: AttendanceKind.free);
    }
  }

  void _openPlayer(AttendanceRecordResult r) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          PlayerDetailScreen(playerId: r.player.id, academyId: widget.academyId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مسح QR'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_canUseCamera)
              _CameraButton(onPressed: _processing ? null : _scanWithCamera)
            else
              _DesktopHint(),

            Gap(16.h),

            // حقل الإدخال اليدوي / قارئ USB (متاح على المنصتين).
            TextField(
              controller: _manualController,
              focusNode: _manualFocus,
              textInputAction: TextInputAction.done,
              // رقم الكود فقط يكفي: 123 = Y-0123.
              keyboardType: TextInputType.number,
              onSubmitted: _handleCode,
              decoration: InputDecoration(
                labelText: 'إدخال الكود يدوياً أو عبر قارئ USB',
                hintText: 'اكتب الرقم فقط — مثال: 1 أو Y-0001',
                filled: true,
                fillColor: AppColors.white,
                prefixIcon: const Icon(Icons.qr_code_2_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _handleCode(_manualController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),

            Gap(20.h),

            if (_processing)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _ErrorCard(message: _error!)
            else if (result != null)
              _ResultCard(
                result: result,
                onOpenPlayer:
                    result.player.id.isEmpty ? null : () => _openPlayer(result),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// زر فتح الكاميرا (Android) — يفتح ماسح QR كامل الشاشة
// ---------------------------------------------------------------------------

class _CameraButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _CameraButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner, size: 64.sp, color: AppColors.primary),
            Gap(10.h),
            Text(
              'اضغط لفتح الكاميرا ومسح البطاقة',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// تلميح سطح المكتب (Windows) — لا كاميرا
// ---------------------------------------------------------------------------

class _DesktopHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.qr_code_scanner, size: 56.sp, color: AppColors.primary),
          Gap(12.h),
          Text(
            'استخدم قارئ QR (USB) أو أدخل كود اللاعب يدوياً في الحقل بالأسفل',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// حوار "اشتراك اللاعب منتهي"
// ---------------------------------------------------------------------------

class _ExpiredDialog extends StatelessWidget {
  final AttendanceRecordResult result;
  const _ExpiredDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    // التعويض يحتاج غياباً في الاشتراك السابق ليُعوَّض.
    final canMakeup = result.stats.absent > 0;
    return AlertDialog(
      title: const Text('اشتراك اللاعب منتهي'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${result.player.fullName} — ${result.player.playerCode}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
            Gap(10.h),
            SubscriptionStatsBanner(stats: result.stats, compact: true),
            Gap(12.h),
            _option(
              context,
              _ExpiredChoice.renew,
              Icons.autorenew,
              AppColors.primary,
              'تجديد',
              'فتح شاشة تجديد الاشتراك (لا يُسجَّل حضور)',
            ),
            _option(
              context,
              _ExpiredChoice.payLater,
              Icons.schedule,
              AppColors.warning,
              'حضور والدفع لاحقاً',
              'يُحتسب من حصص الاشتراك الجديد عند التجديد',
            ),
            _option(
              context,
              _ExpiredChoice.makeup,
              Icons.event_repeat,
              AppColors.secondary,
              'تعويض غياب سابق',
              canMakeup
                  ? 'يُضاف كحضور للاشتراك السابق (يقلّ الغياب يوماً)'
                  : 'لا يوجد غياب في الاشتراك السابق لتعويضه',
              enabled: canMakeup,
            ),
            _option(
              context,
              _ExpiredChoice.free,
              Icons.card_giftcard,
              const Color(0xFF2D9748),
              'حصة مجانية',
              'يُسجَّل الحضور ولا يُحتسب في عدد حصص أي اشتراك',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  Widget _option(BuildContext context, _ExpiredChoice value, IconData icon,
      Color color, String title, String subtitle,
      {bool enabled = true}) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 0,
      color: enabled ? color.withValues(alpha: 0.07) : AppColors.grey100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon, color: enabled ? color : AppColors.grey400),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5.sp)),
        onTap: enabled ? () => Navigator.pop(context, value) : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// بطاقات النتيجة
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 28.sp),
          Gap(12.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AttendanceRecordResult result;
  final VoidCallback? onOpenPlayer;
  const _ResultCard({required this.result, this.onOpenPlayer});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final p = r.player;
    // أخضر للنجاح، لون أساسي لـ "مسجَّل مسبقاً اليوم".
    final Color accent =
        r.alreadyToday ? AppColors.primary : const Color(0xFF2D9748);
    final IconData icon =
        r.alreadyToday ? Icons.info_outline : Icons.check_circle_outline;

    return InkWell(
      onTap: onOpenPlayer,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: ClipOval(
                    child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: p.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(Icons.person,
                                color: accent, size: 32.sp),
                          )
                        : Icon(Icons.person, color: accent, size: 32.sp),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.fullName,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey900,
                        ),
                      ),
                      Gap(2.h),
                      Text(
                        p.playerCode,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (p.sport != null && p.sport!.isNotEmpty) ...[
                        Gap(2.h),
                        Text(
                          p.sport!,
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.grey500),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Gap(12.h),
            Row(
              children: [
                Icon(icon, color: accent, size: 22.sp),
                Gap(8.w),
                Expanded(
                  child: Text(
                    r.message,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                AttendanceKindBadge(kind: r.kind),
              ],
            ),
            Gap(12.h),
            // حالة الاشتراك (نشط / قرب على الانتهاء / منتهي) + الحضور والغياب
            // منذ بداية الاشتراك.
            SubscriptionStatsBanner(stats: r.stats, compact: true),
            if (onOpenPlayer != null) ...[
              Gap(10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('اضغط لفتح صفحة اللاعب',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_left,
                      size: 18.sp, color: AppColors.primary),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
