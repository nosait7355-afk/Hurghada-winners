import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// خدمة تصدير بطاقة اللاعب إلى PDF.
///
/// لا ترسم هذه الخدمة البطاقة إطلاقاً — بل تستقبل صورة PNG عالية الدقة تم
/// التقاطها مباشرةً من Widget البطاقة المعروض داخل التطبيق (عبر RepaintBoundary)،
/// ثم تضعها داخل صفحة PDF مع الحفاظ الكامل على نسبة الأبعاد دون أي Stretch.
///
/// بذلك تكون البطاقة في الـ PDF مطابقة 100% للبطاقة الظاهرة داخل التطبيق:
/// نفس الـ Gradient والـ Shadow والـ BorderRadius وأماكن الصورة وQR والنصوص
/// ونفس الخطوط والألوان.
class PlayerCardPdfService {
  PlayerCardPdfService._();

  /// يضع صورة البطاقة الملتقطة داخل صفحة PDF.
  ///
  /// - البطاقة أفقية (نسبة 1.586) → الصفحة A4 أفقية (Landscape).
  /// - `BoxFit.contain` يحافظ على نسبة الأبعاد بدون أي تمدّد أو تشويه.
  /// - الصورة ملتقطة بدقة ≥ 300 DPI لضمان جودة طباعة عالية.
  static Future<Uint8List> generateFromImage(
    Uint8List pngBytes, {
    bool landscape = true,
  }) async {
    if (pngBytes.isEmpty) {
      throw StateError('تعذّر إنشاء البطاقة — صورة البطاقة فارغة');
    }

    final doc = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    final base = landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4.portrait;

    doc.addPage(
      pw.Page(
        // هامش متساوٍ بسيط حول البطاقة داخل الصفحة.
        pageFormat: base.copyWith(
          marginTop: 24,
          marginBottom: 24,
          marginLeft: 24,
          marginRight: 24,
        ),
        build: (_) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );

    return doc.save();
  }
}
