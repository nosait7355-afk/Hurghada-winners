import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/network/api_client.dart';
import 'package:hurghada_winners/features/attendance/presentation/widgets/web_qr_scanner.dart';
import 'package:hurghada_winners/features/staff/data/staff_scan_service.dart';
import 'package:hurghada_winners/features/staff/domain/entities/staff_entity.dart';
import 'package:hurghada_winners/features/staff/presentation/providers/staff_provider.dart';
import 'package:hurghada_winners/features/staff/presentation/screens/staff_attendance_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// حضور وانصراف المدربين — الأدمن يمسح QR المدرب: أول مسح في اليوم حضور،
/// والثاني انصراف. القائمة أسفل الشاشة بديل يدوي (بدون كاميرا).
class StaffScanScreen extends ConsumerStatefulWidget {
  final String academyId;
  const StaffScanScreen({super.key, required this.academyId});

  @override
  ConsumerState<StaffScanScreen> createState() => _StaffScanScreenState();
}

class _StaffScanScreenState extends ConsumerState<StaffScanScreen> {
  final _service = StaffScanService(sl<ApiClient>());
  bool _busy = false;
  StaffScanResult? _last;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(staffProvider.notifier).load(academyId: widget.academyId));
  }

  Future<void> _scanWithCamera() async {
    String? code;
    try {
      if (kIsWeb) {
        code = await showWebQrScanner(context);
      } else {
        final result = await BarcodeScanner.scan();
        if (result.type == ResultType.Barcode) code = result.rawContent;
        if (result.type == ResultType.Error) {
          setState(() => _error = 'تعذّر قراءة الكود، حاول مرة أخرى');
          return;
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذّر فتح الكاميرا — استخدم القائمة بالأسفل');
      }
      return;
    }
    if (code != null && code.trim().isNotEmpty) await _submit(code);
  }

  Future<void> _submit(String code) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _service.scan(code);
      if (!mounted) return;
      setState(() => _last = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is AppException && e.message.trim().isNotEmpty
          ? e.message
          : 'تعذّر التسجيل. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffProvider);
    final staff = (staffAsync.valueOrNull?.staff ?? const <StaffEntity>[])
        .where((s) => s.isActive)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حضور وانصراف المدربين'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          SizedBox(
            height: 56.h,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _scanWithCamera,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.qr_code_scanner),
              label: const Text('مسح QR المدرب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                textStyle:
                    TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
            ),
          ),
          Gap(6.h),
          Text(
            'أول مسح في اليوم = حضور • المسح الثاني = انصراف',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
          ),
          if (_error != null) ...[
            Gap(12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(_error!,
                  style: TextStyle(color: AppColors.error, fontSize: 13.sp)),
            ),
          ],
          if (_last != null) ...[
            Gap(12.h),
            _ResultCard(result: _last!),
          ],
          Gap(20.h),
          Text('تسجيل يدوي',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
          Gap(8.h),
          if (staffAsync.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (staff.isEmpty)
            Text('لا يوجد مدربون',
                style: TextStyle(color: AppColors.grey500, fontSize: 13.sp))
          else
            for (final s in staff) ...[
              Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: s.photoUrl != null
                        ? CachedNetworkImageProvider(s.photoUrl!)
                        : null,
                    child: s.photoUrl == null
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  title: Text(s.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(s.position),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => StaffAttendanceScreen(staff: s))),
                  trailing: OutlinedButton(
                    onPressed: _busy ? null : () => _submit(staffQrData(s.id)),
                    child: const Text('تسجيل'),
                  ),
                ),
              ),
              Gap(8.h),
            ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final StaffScanResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.isCheckIn ? AppColors.success : AppColors.secondary;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26.r,
            backgroundColor: AppColors.white,
            backgroundImage: result.photoUrl != null
                ? CachedNetworkImageProvider(result.photoUrl!)
                : null,
            child: result.photoUrl == null
                ? Icon(Icons.person, color: color)
                : null,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    result.isCheckIn
                        ? 'تم تسجيل الحضور ✅'
                        : 'تم تسجيل الانصراف 👋',
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Gap(2.h),
                Text(result.staffName,
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w700)),
                Gap(2.h),
                Text(
                  [
                    if (result.checkIn != null) 'حضور ${result.checkIn}',
                    if (result.checkOut != null) 'انصراف ${result.checkOut}',
                  ].join(' • '),
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
