import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/utils/local_image/local_image.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/offers/data/offer.dart';
import 'package:hurghada_winners/features/offers/data/offers_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// إضافة/تعديل عرض. يعيد true عند الحفظ.
class OfferFormScreen extends ConsumerStatefulWidget {
  final Offer? existing;
  const OfferFormScreen({super.key, this.existing});

  @override
  ConsumerState<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends ConsumerState<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _details = TextEditingController(text: widget.existing?.details);
  late final _discountValue = TextEditingController(
      text: widget.existing?.discountValue?.toStringAsFixed(0));

  String? _discountType; // null = بلا خصم
  late DateTime _start;
  late DateTime _end;
  Set<String> _academyIds = {}; // فارغة = كل الفروع
  XFile? _image;
  bool _removeImage = false;
  bool _saving = false;

  final _fmt = DateFormat('dd/MM/yyyy', 'ar');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    _discountType = e?.discountType;
    _start = e?.startDate ?? DateTime(now.year, now.month, now.day);
    _end = e?.endDate ?? _start.add(const Duration(days: 14));
    _academyIds = {...?e?.academyIds};
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _discountValue.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (img != null) {
      setState(() {
        _image = img;
        _removeImage = false;
      });
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end.isBefore(_start)) {
      _toast('تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
      return;
    }
    setState(() => _saving = true);
    final input = OfferInput(
      title: _title.text.trim(),
      details: _details.text.trim(),
      discountType: _discountType,
      discountValue: _discountType == null
          ? null
          : double.tryParse(_discountValue.text.trim()),
      startDate: _start,
      endDate: _end,
      academyIds: _academyIds.toList(),
      imagePath: _image?.path,
      removeImage: _removeImage,
    );
    try {
      final service = sl<OffersService>();
      if (widget.existing == null) {
        await service.create(input);
      } else {
        await service.update(widget.existing!.id, input);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e is AppException ? e.message : 'تعذّر حفظ العرض');
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    final isSuper =
        ref.watch(authStateProvider).valueOrNull?.user?.isSuperAdmin ?? false;
    final academies =
        isSuper ? (ref.watch(academiesProvider).valueOrNull ?? const []) : const [];
    final existingImage = widget.existing?.imageUrl;
    final showExisting = _image == null &&
        !_removeImage &&
        existingImage != null &&
        existingImage.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'إضافة عرض' : 'تعديل العرض'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            // الصورة (اختيارية)
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                height: 170.h,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.grey300),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image != null
                    ? Image(image: pickedImageProvider(_image!.path), fit: BoxFit.cover)
                    : showExisting
                        ? CachedNetworkImage(imageUrl: existingImage, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 40.sp, color: AppColors.primary),
                              Gap(6.h),
                              const Text('صورة العرض (اختياري)'),
                            ],
                          ),
              ),
            ),
            if (_image != null || showExisting)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _image = null;
                    _removeImage = true;
                  }),
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: const Text('إزالة الصورة',
                      style: TextStyle(color: AppColors.error)),
                ),
              ),
            Gap(12.h),
            TextFormField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'عنوان العرض *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
            ),
            TextFormField(
              controller: _details,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(labelText: 'تفاصيل العرض'),
            ),
            Gap(8.h),
            const Text('الخصم', style: TextStyle(fontWeight: FontWeight.w700)),
            Gap(6.h),
            Wrap(
              spacing: 8.w,
              children: [
                for (final (value, label) in const [
                  (null, 'بدون'),
                  ('percent', 'نسبة %'),
                  ('amount', 'مبلغ'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _discountType == value,
                    onSelected: (_) => setState(() => _discountType = value),
                  ),
              ],
            ),
            if (_discountType != null)
              TextFormField(
                controller: _discountValue,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      _discountType == 'percent' ? 'نسبة الخصم (%)' : 'قيمة الخصم',
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'أدخل قيمة صحيحة';
                  if (_discountType == 'percent' && n > 100) {
                    return 'لا يمكن أن تتجاوز 100%';
                  }
                  return null;
                },
              ),
            Gap(16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: true),
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text('من ${_fmt.format(_start)}'),
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: false),
                    icon: const Icon(Icons.event_busy_outlined, size: 18),
                    label: Text('حتى ${_fmt.format(_end)}'),
                  ),
                ),
              ],
            ),
            // الفروع — للحساب الرئيسي فقط؛ مدير الفرع يضيف لفرعه تلقائياً.
            if (isSuper) ...[
              Gap(16.h),
              const Text('الفروع', style: TextStyle(fontWeight: FontWeight.w700)),
              Gap(6.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  FilterChip(
                    label: const Text('كل الفروع'),
                    selected: _academyIds.isEmpty,
                    onSelected: (_) => setState(() => _academyIds = {}),
                  ),
                  for (final a in academies)
                    FilterChip(
                      label: Text(a.name),
                      selected: _academyIds.contains(a.id),
                      onSelected: (on) => setState(() {
                        final next = {..._academyIds};
                        on ? next.add(a.id) : next.remove(a.id);
                        _academyIds = next;
                      }),
                    ),
                ],
              ),
            ],
            Gap(24.h),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : Text(widget.existing == null ? 'إضافة العرض' : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}
