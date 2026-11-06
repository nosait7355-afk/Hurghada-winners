import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/features/player/data/join_request_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

final _joinRequestDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, requestId) async {
  return sl<JoinRequestService>().getDetail(requestId);
});

/// تفاصيل طلب انضمام: كل البيانات المُرسَلة + صورة الإيصال + إمكانية تعديل
/// البيانات، ثم الموافقة (بتحديد تاريخ/مبلغ الاشتراك) أو الرفض.
class JoinRequestDetailScreen extends ConsumerStatefulWidget {
  final String academyId;
  final String requestId;
  const JoinRequestDetailScreen({super.key, required this.academyId, required this.requestId});

  @override
  ConsumerState<JoinRequestDetailScreen> createState() => _JoinRequestDetailScreenState();
}

class _JoinRequestDetailScreenState extends ConsumerState<JoinRequestDetailScreen> {
  bool _busy = false;

  void _snack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? AppColors.error : AppColors.success),
    );
  }

  Future<void> _editFields(Map<String, dynamic> data) async {
    final fullNameCtrl = TextEditingController(text: data['fullName'] as String? ?? '');
    final parentNameCtrl = TextEditingController(text: data['parentName'] as String? ?? '');
    final parentPhoneCtrl = TextEditingController(text: data['parentPhone'] as String? ?? '');
    final playerPhoneCtrl = TextEditingController(text: data['playerPhone'] as String? ?? '');
    final notesCtrl = TextEditingController(text: data['notes'] as String? ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20.w, right: 20.w, top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعديل بيانات الطلب', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
              Gap(16.h),
              TextField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: 'اسم اللاعب')),
              Gap(10.h),
              TextField(controller: parentNameCtrl, decoration: const InputDecoration(labelText: 'اسم ولي الأمر')),
              Gap(10.h),
              TextField(controller: parentPhoneCtrl, decoration: const InputDecoration(labelText: 'هاتف ولي الأمر')),
              Gap(10.h),
              TextField(controller: playerPhoneCtrl, decoration: const InputDecoration(labelText: 'هاتف اللاعب')),
              Gap(10.h),
              TextField(controller: notesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات')),
              Gap(16.h),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != true) return;
    setState(() => _busy = true);
    try {
      await sl<JoinRequestService>().updateFields(widget.requestId, {
        'fullName': fullNameCtrl.text.trim(),
        'parentName': parentNameCtrl.text.trim(),
        'parentPhone': parentPhoneCtrl.text.trim(),
        if (playerPhoneCtrl.text.trim().isNotEmpty) 'playerPhone': playerPhoneCtrl.text.trim(),
        'notes': notesCtrl.text.trim(),
      });
      ref.invalidate(_joinRequestDetailProvider(widget.requestId));
      _snack('تم حفظ التعديلات', error: false);
    } catch (e) {
      _snack(e is AppException ? e.message : 'تعذّر حفظ التعديلات');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> data) async {
    final amountCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    final dateFmt = DateFormat('dd/MM/yyyy', 'ar');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('الموافقة على الطلب'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'مبلغ الاشتراك'),
                ),
                Gap(12.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ البداية'),
                  subtitle: Text(dateFmt.format(startDate)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx, initialDate: startDate,
                      firstDate: DateTime(2020), lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        startDate = picked;
                        if (endDate.isBefore(startDate)) {
                          endDate = startDate.add(const Duration(days: 30));
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ النهاية'),
                  subtitle: Text(dateFmt.format(endDate)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: endDate.isAfter(startDate) ? endDate : startDate.add(const Duration(days: 1)),
                      firstDate: startDate.add(const Duration(days: 1)), lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => endDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('موافقة')),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount < 0) {
      _snack('الرجاء إدخال مبلغ اشتراك صحيح');
      return;
    }

    setState(() => _busy = true);
    try {
      await sl<JoinRequestService>().approve(
        widget.requestId,
        amount: amount,
        startDate: DateFormat('yyyy-MM-dd').format(startDate),
        endDate: DateFormat('yyyy-MM-dd').format(endDate),
      );
      if (!mounted) return;
      _snack('تمت الموافقة على الطلب بنجاح', error: false);
      Navigator.of(context).pop();
    } catch (e) {
      _snack(e is AppException ? e.message : 'تعذّرت الموافقة على الطلب');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'سبب الرفض (اختياري)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await sl<JoinRequestService>().reject(widget.requestId, reason: reasonCtrl.text.trim());
      if (!mounted) return;
      _snack('تم رفض الطلب', error: false);
      Navigator.of(context).pop();
    } catch (e) {
      _snack(e is AppException ? e.message : 'تعذّر رفض الطلب');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _zoomReceipt(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5, maxScale: 4,
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(_joinRequestDetailProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تفاصيل طلب الانضمام'), centerTitle: true),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(
          child: Text('تعذّر تحميل الطلب', style: TextStyle(color: AppColors.error)),
        ),
        data: (data) {
          final birthDate = DateTime.tryParse(data['birthDate'] as String? ?? '');
          // الطلب المرفوض يبقى قابلاً للتعديل والموافقة، لكن لا يُرفض مرة أخرى.
          final isRejected = data['registrationStatus'] == 'rejected';
          final rejectionReason = data['rejectionReason'] as String?;
          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 100.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isRejected) ...[
                      Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.cancel_outlined, color: AppColors.error),
                            Gap(10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'طلب مرفوض',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
                                    Gap(4.h),
                                    Text(
                                      rejectionReason,
                                      style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey700),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap(14.h),
                    ],
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('الفرع', data['branch'] as String? ?? ''),
                          _row('اسم اللاعب', data['fullName'] as String? ?? ''),
                          _row('تاريخ الميلاد',
                              birthDate != null ? DateFormat('dd/MM/yyyy', 'ar').format(birthDate) : ''),
                          _row('اسم ولي الأمر', data['parentName'] as String? ?? ''),
                          _row('صلة القرابة', data['parentRelationship'] as String? ?? ''),
                          _row('هاتف ولي الأمر', data['parentPhone'] as String? ?? ''),
                          if ((data['playerPhone'] as String?)?.isNotEmpty == true)
                            _row('هاتف اللاعب', data['playerPhone'] as String),
                          if ((data['notes'] as String?)?.isNotEmpty == true)
                            _row('ملاحظات', data['notes'] as String),
                        ],
                      ),
                    ),
                    Gap(14.h),
                    Text('إيصال الدفع', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                    Gap(8.h),
                    if (data['receipt_url'] != null)
                      GestureDetector(
                        onTap: () => _zoomReceipt(data['receipt_url'] as String),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: Image.network(
                            data['receipt_url'] as String,
                            height: 220.h, width: double.infinity, fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      const Text('لا توجد صورة إيصال', style: TextStyle(color: AppColors.grey500)),
                    Gap(14.h),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _editFields(data),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('تعديل البيانات'),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
                  ),
                  child: Row(
                    children: [
                      if (!isRejected) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _reject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            child: const Text('رفض'),
                          ),
                        ),
                        Gap(12.w),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy ? null : () => _approve(data),
                          child: _busy
                              ? SizedBox(
                                  height: 18.h, width: 18.h,
                                  child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                )
                              : const Text('موافقة'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(label, style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
