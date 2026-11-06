import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/store/data/store_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// نتيجة نموذج المنتج: عند الإضافة يحمل مسار الصورة؛ عند التعديل قد لا يحمله.
class ProductFormResult {
  final String? imagePath; // null عند التعديل بدون تغيير الصورة
  final String name;
  final String description;
  final double price;
  final bool isAvailable;
  const ProductFormResult({
    this.imagePath,
    required this.name,
    required this.description,
    required this.price,
    required this.isAvailable,
  });
}

/// نموذج موحّد: إضافة منتج (صورة + اسم + سعر + وصف + توفّر) أو تعديل
/// (نفس الحقول عدا الصورة). يعيد ProductFormResult أو null عند الإلغاء.
class ProductFormDialog extends StatefulWidget {
  final StoreProduct? existing; // null = إضافة
  final String currencyLabel;
  const ProductFormDialog({super.key, this.existing, required this.currencyLabel});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  XFile? _picked;
  bool _isAvailable = true;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description;
      _priceCtrl.text =
          e.price == e.price.roundToDouble() ? e.price.toInt().toString() : e.price.toString();
      _isAvailable = e.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
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
      setState(() => _error = 'اسم المنتج مطلوب');
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim().replaceAll(',', ''));
    if (price == null || price < 0) {
      setState(() => _error = 'أدخل سعراً صحيحاً');
      return;
    }
    if (!_isEdit && _picked == null) {
      setState(() => _error = 'اختر صورة المنتج أولاً');
      return;
    }
    Navigator.pop(
      context,
      ProductFormResult(
        imagePath: _picked?.path,
        name: name,
        description: _descCtrl.text.trim(),
        price: price,
        isAvailable: _isAvailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل المنتج' : 'إضافة منتج'),
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
                    : (_isEdit ? 'تغيير الصورة (اختياري)' : 'اختيار صورة المنتج'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'اسم المنتج'),
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
            TextField(
              controller: _descCtrl,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('متاح للبيع'),
              value: _isAvailable,
              activeColor: AppColors.success,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
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
