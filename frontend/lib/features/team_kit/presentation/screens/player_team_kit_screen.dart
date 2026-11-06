import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/widgets/full_screen_image_viewer.dart';
import 'package:hurghada_winners/features/store/presentation/widgets/product_card.dart';
import 'package:hurghada_winners/features/team_kit/data/kit_booking.dart';
import 'package:hurghada_winners/features/team_kit/data/team_kit.dart';
import 'package:hurghada_winners/features/team_kit/data/team_kit_service.dart';
import 'package:hurghada_winners/features/team_kit/presentation/providers/team_kit_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

/// طقم الفريق — جهة اللاعب: عرض الطقم الحالي وحجزه (اسم + رقم على التيشرت
/// + مقاس). الحجز يُرسَل لمراجعة إدارة الأكاديمية قبل اعتماده.
class PlayerTeamKitScreen extends ConsumerWidget {
  const PlayerTeamKitScreen({super.key});

  Future<void> _openBookingForm(BuildContext context, WidgetRef ref, TeamKit kit) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_BookingFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => _BookingFormSheet(kit: kit),
    );
    if (result == null) return;
    try {
      await sl<TeamKitService>().createPlayerBooking(
        size: result.size,
        receiptPath: result.receiptPath,
      );
      messenger.showSnackBar(const SnackBar(
        content: Text('تم إرسال طلب الحجز، بانتظار موافقة إدارة الأكاديمية'),
        backgroundColor: AppColors.success,
      ));
      ref.invalidate(playerKitProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          e is AppException && e.message.trim().isNotEmpty
              ? e.message
              : 'تعذّر إرسال الحجز. حاول مرة أخرى.',
        ),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kitAsync = ref.watch(playerKitProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('طقم الفريق'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(playerKitProvider),
          ),
        ],
      ),
      body: kitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 44),
              SizedBox(height: 12.h),
              const Text('تعذّر تحميل طقم الفريق'),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () => ref.invalidate(playerKitProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (kit) {
          if (kit == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checkroom_outlined, size: 52.sp, color: AppColors.grey400),
                  SizedBox(height: 12.h),
                  Text('لا يوجد طقم فريق متاح حالياً',
                      style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: kit.imageUrl.isEmpty
                      ? null
                      : () => showFullScreenImage(context, kit.imageUrl),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: CachedNetworkImage(
                      imageUrl: kit.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.grey100),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.grey100,
                        child: Icon(Icons.image_not_supported_outlined,
                            color: AppColors.grey400, size: 40.sp),
                      ),
                    ),
                  ),
                ),
                ),
                Gap(14.h),
                Text(kit.name, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
                Gap(6.h),
                Text(
                  ProductCard.formatPrice(kit.price),
                  style: TextStyle(
                      fontSize: 20.sp, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
                Gap(24.h),
                if (kit.myBooking != null) ...[
                  _BookingStatusCard(booking: kit.myBooking!),
                  Gap(16.h),
                ],
                // حجز قيد المراجعة أو مؤكد يمنع حجزاً جديداً؛ المرفوض يسمح.
                if (kit.myBooking == null || kit.myBooking!.status == 'rejected')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openBookingForm(context, ref, kit),
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(kit.myBooking == null ? 'حجز' : 'حجز مرة أخرى'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// حالة حجز اللاعب: قيد المراجعة / تم تأكيد الحجز / مرفوض.
class _BookingStatusCard extends StatelessWidget {
  final KitBooking booking;
  const _BookingStatusCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (booking.status) {
      'approved' => ('تم تأكيد الحجز', AppColors.success, Icons.verified),
      'rejected' => ('تم رفض الحجز', AppColors.error, Icons.cancel_outlined),
      _ => ('قيد المراجعة', AppColors.warning, Icons.hourglass_top),
    };
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28.sp),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 15.sp, fontWeight: FontWeight.w800, color: color)),
                Gap(4.h),
                Text(
                  booking.status == 'rejected'
                      ? 'يمكنك إرسال حجز جديد'
                      : 'المقاس: ${booking.size}',
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

class _BookingFormResult {
  final String size;
  final String receiptPath;
  const _BookingFormResult({
    required this.size,
    required this.receiptPath,
  });
}

class _BookingFormSheet extends StatefulWidget {
  final TeamKit kit;
  const _BookingFormSheet({required this.kit});

  @override
  State<_BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<_BookingFormSheet> {
  String? _size;
  String? _error;
  XFile? _receipt;

  Future<void> _pickReceipt() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (img == null || !mounted) return;
    // الصور الأكبر من 2MB تُصغَّر تلقائياً عند الرفع (buildImageMultipart).
    setState(() {
      _receipt = img;
      _error = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _size = widget.kit.availableSizes.isNotEmpty ? widget.kit.availableSizes.first : null;
  }

  void _submit() {
    if (_size == null) {
      setState(() => _error = 'اختر مقاساً');
      return;
    }
    if (_receipt == null) {
      setState(() => _error = 'ارفع صورة إيصال الدفع');
      return;
    }
    Navigator.pop(
      context,
      _BookingFormResult(
        size: _size!,
        receiptPath: _receipt!.path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18.w,
          right: 18.w,
          top: 14.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              Text('حجز طقم الفريق',
                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800)),
              Gap(16.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('المقاس', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
              ),
              Gap(8.h),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.kit.availableSizes.map((s) {
                  return ChoiceChip(
                    label: Text(s),
                    selected: _size == s,
                    onSelected: (_) => setState(() => _size = s),
                    selectedColor: AppColors.primaryContainer,
                  );
                }).toList(),
              ),
              Gap(16.h),
              // إيصال الدفع — مطلوب؛ يراجعه المدير قبل الموافقة على الحجز.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('صورة إيصال الدفع (مطلوب)',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
              ),
              Gap(8.h),
              InkWell(
                onTap: _pickReceipt,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _receipt == null ? AppColors.grey300 : AppColors.success,
                    ),
                    color: _receipt == null ? null : AppColors.successLight,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _receipt == null
                            ? Icons.receipt_long_outlined
                            : Icons.check_circle_outline,
                        color: _receipt == null ? AppColors.grey500 : AppColors.success,
                        size: 22.sp,
                      ),
                      Gap(10.w),
                      Expanded(
                        child: Text(
                          _receipt == null
                              ? 'اضغط لاختيار صورة الإيصال من المعرض'
                              : 'تم اختيار صورة الإيصال',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: _receipt == null ? AppColors.grey600 : AppColors.success,
                          ),
                        ),
                      ),
                      if (_receipt != null)
                        IconButton(
                          tooltip: 'إزالة',
                          onPressed: () => setState(() => _receipt = null),
                          icon: Icon(Icons.close, size: 18.sp),
                        ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                Gap(8.h),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              Gap(20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14.h)),
                  child: const Text('تأكيد الحجز'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
