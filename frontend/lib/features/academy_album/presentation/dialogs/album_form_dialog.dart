import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/academy_album/data/album_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// نتيجة نموذج الألبوم: عند الإضافة يحمل مسار الصورة؛ عند التعديل لا يحمله.
class AlbumFormResult {
  final String? imagePath; // null عند التعديل
  final String title;
  final String description;
  const AlbumFormResult({this.imagePath, required this.title, required this.description});
}

/// نموذج موحّد: إضافة صورة (اختيار من المعرض + عنوان + وصف) أو تعديل
/// (عنوان + وصف فقط). يعيد AlbumFormResult أو null عند الإلغاء.
class AlbumFormDialog extends StatefulWidget {
  final AlbumImage? existing; // null = إضافة
  const AlbumFormDialog({super.key, this.existing});

  @override
  State<AlbumFormDialog> createState() => _AlbumFormDialogState();
}

class _AlbumFormDialogState extends State<AlbumFormDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  XFile? _picked;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _descCtrl.text = widget.existing!.description;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'العنوان مطلوب');
      return;
    }
    if (!_isEdit && _picked == null) {
      setState(() => _error = 'اختر صورة أولاً');
      return;
    }
    Navigator.pop(
      context,
      AlbumFormResult(
        imagePath: _picked?.path,
        title: title,
        description: _descCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل الصورة' : 'إضافة صورة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isEdit) ...[
              OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_picked == null ? 'اختيار صورة من المعرض' : 'تم اختيار الصورة'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _titleCtrl,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            TextField(
              controller: _descCtrl,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
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
