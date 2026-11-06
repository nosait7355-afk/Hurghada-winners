import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/team_kit/data/team_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// نتيجة نموذج الطقم: عند الإضافة يحمل مسار الصورة إلزامياً؛ عند التعديل اختياري.
class KitFormResult {
  final String? imagePath; // null عند التعديل بدون تغيير الصورة
  final String name;
  final double price;
  final List<String> availableSizes;
  const KitFormResult({
    this.imagePath,
    required this.name,
    required this.price,
    required this.availableSizes,
  });
}

/// نموذج موحّد لإضافة/تعديل طقم الفريق: صورة + اسم + سعر + اختيار المقاسات
/// المتاحة من القائمة الثابتة (5XS → 5XL).
class KitFormDialog extends StatefulWidget {
  final TeamKit? existing; // null = إضافة
  final String currencyLabel;
  const KitFormDialog({super.key, this.existing, required this.currencyLabel});

  @override
  State<KitFormDialog> createState() => _KitFormDialogState();
}

class _KitFormDialogState extends State<KitFormDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  XFile? _picked;
  final Set<String> _sizes = {};
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _priceCtrl.text =
          e.price == e.price.roundToDouble() ? e.price.toInt().toString() : e.price.toString();
      _sizes.addAll(e.availableSizes);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (img == null) return;
    // الصور الأكبر من 2MB تُصغَّر تلقائياً عند الرفع (buildImageMultipart).
    setState(() {
      _picked = img;
      _error = null;
    });
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'اسم الطقم مطلوب');
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim().replaceAll(',', ''));
    if (price == null || price < 0) {
      setState(() => _error = 'أدخل سعراً صحيحاً');
      return;
    }
    if (!_isEdit && _picked == null) {
      setState(() => _error = 'اختر صورة الطقم أولاً');
      return;
    }
    if (_sizes.isEmpty) {
      setState(() => _error = 'اختر مقاساً واحداً على الأقل');
      return;
    }
    // نحافظ على ترتيب القائمة الثابتة بدل ترتيب الاختيار.
    final ordered = kKitSizes.where(_sizes.contains).toList();
    Navigator.pop(
      context,
      KitFormResult(
        imagePath: _picked?.path,
        name: name,
        price: price,
        availableSizes: ordered,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل طقم الفريق' : 'إضافة طقم الفريق'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _picked != null
                    ? 'تم اختيار الصورة'
                    : (_isEdit ? 'تغيير الصورة (اختياري)' : 'اختيار صورة الطقم'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'اسم الطقم'),
            ),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'السعر',
                suffixText: widget.currencyLabel,
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('المقاسات المتاحة', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kKitSizes.map((s) {
                final selected = _sizes.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _sizes.add(s);
                    } else {
                      _sizes.remove(s);
                    }
                  }),
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }
}
