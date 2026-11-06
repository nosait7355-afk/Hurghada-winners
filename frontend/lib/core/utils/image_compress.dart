import 'package:hurghada_winners/core/utils/image_size_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// الحجم المستهدف بعد التصغير — أقل من حد الخادم (2MB) بهامش أمان.
const int kUploadTargetBytes = kMaxImageBytes - 200 * 1024;

/// يعيد الصورة كما هي إن كانت تحت الحد، وإلا يصغّرها (أبعاد ثم جودة) إلى
/// JPEG تحت الحد. بدل رفض الصورة الكبيرة نصغّرها تلقائياً قبل الرفع، فلا يرى
/// المستخدم رسالة "الحجم أكبر من 2 ميجابايت" أبداً.
///
/// مكتبة image بـ Dart خالص (موجودة أصلاً عبر pdf) — لا كود أصلي إضافي على
/// بناء أندرويد. على الجوال يعمل في isolate منفصل حتى لا تتجمّد الواجهة.
Future<Uint8List> shrinkImageForUpload(Uint8List bytes) async {
  if (bytes.length <= kUploadTargetBytes) return bytes;
  return compute(_shrink, bytes);
}

Uint8List _shrink(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  // صيغة غير مقروءة: نتركها كما هي ويحكم الخادم.
  if (decoded == null) return bytes;
  // صور الكاميرا تحمل اتجاهها في EXIF؛ نطبّقه قبل إعادة الترميز التي تحذفه.
  final source = img.bakeOrientation(decoded);

  for (final maxSide in const [1600, 1280, 1024, 800]) {
    final resized = _fit(source, maxSide);
    for (final quality in const [85, 72, 60]) {
      final out = img.encodeJpg(resized, quality: quality);
      if (out.length <= kUploadTargetBytes) return out;
    }
  }
  return img.encodeJpg(_fit(source, 640), quality: 55);
}

img.Image _fit(img.Image image, int maxSide) {
  if (image.width <= maxSide && image.height <= maxSide) return image;
  return image.width >= image.height
      ? img.copyResize(image, width: maxSide, interpolation: img.Interpolation.average)
      : img.copyResize(image, height: maxSide, interpolation: img.Interpolation.average);
}
