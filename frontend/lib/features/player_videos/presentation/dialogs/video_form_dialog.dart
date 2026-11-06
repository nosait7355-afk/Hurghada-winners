import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';
import 'package:flutter/material.dart';

/// نتيجة نموذج الفيديو.
class VideoFormResult {
  final String title;
  final String description;
  final String url;
  const VideoFormResult({
    required this.title,
    required this.description,
    required this.url,
  });
}

/// نموذج موحّد لإضافة فيديو أو تعديله. الفيديو رابط خارجي، فلا رفع ملفات.
class VideoFormDialog extends StatefulWidget {
  final PlayerVideo? existing; // null = إضافة

  /// صورة (إضافة أو تعديل): بلا حقل رابط، والعنوان اختياري عند الإضافة.
  final bool imageMode;
  const VideoFormDialog({super.key, this.existing, this.imageMode = false});

  @override
  State<VideoFormDialog> createState() => _VideoFormDialogState();
}

class _VideoFormDialogState extends State<VideoFormDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _error;

  bool get _isEdit => widget.existing != null;
  bool get _isImage => widget.imageMode || (widget.existing?.isImage ?? false);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _urlCtrl.text = e.url;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  /// تحقّق مبدئي في الواجهة يوفّر رحلة للخادم؛ الخادم يبقى المرجع النهائي
  /// (نفس القائمة البيضاء في utils/videoLink.js).
  String? _validateUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'رابط الفيديو مطلوب';
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return 'الرابط غير صحيح';
    if (uri.scheme != 'https') return 'الرابط يجب أن يبدأ بـ https';
    const allowed = {
      'youtube.com',
      'www.youtube.com',
      'm.youtube.com',
      'youtu.be',
      'drive.google.com',
    };
    if (!allowed.contains(uri.host.toLowerCase())) {
      return 'يُقبل رابط يوتيوب أو Google Drive فقط';
    }
    return null;
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (_isImage) {
      if (_isEdit && title.isEmpty) {
        setState(() => _error = 'العنوان مطلوب');
        return;
      }
      Navigator.pop(
        context,
        VideoFormResult(
            title: title, description: _descCtrl.text.trim(), url: ''),
      );
      return;
    }
    if (title.isEmpty) {
      setState(() => _error = 'العنوان مطلوب');
      return;
    }
    final urlError = _validateUrl(_urlCtrl.text);
    if (urlError != null) {
      setState(() => _error = urlError);
      return;
    }
    Navigator.pop(
      context,
      VideoFormResult(
        title: title,
        description: _descCtrl.text.trim(),
        url: _urlCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isImage
          ? (_isEdit ? 'تعديل الصورة' : 'إضافة صورة')
          : (_isEdit ? 'تعديل الفيديو' : 'إضافة فيديو')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isImage) ...[
            TextField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'رابط الفيديو',
                hintText: 'https://youtu.be/…',
                counterText: '',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'يُقبل رابط من YouTube أو Google Drive فقط.',
              style: TextStyle(fontSize: 12, color: AppColors.grey500),
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
