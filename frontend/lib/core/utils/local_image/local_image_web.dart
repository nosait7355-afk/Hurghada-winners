import 'package:flutter/widgets.dart';

// على الويب يعيد image_picker مسار `blob:` لا مسار ملف — و`dart:io` غير
// متاحة أصلاً. المتصفح يحمّل blob URL كأي رابط، فـ NetworkImage تكفي.
// نفس منطق [buildImageMultipart] في core/utils/multipart.
ImageProvider pickedImageProvider(String pathOrBlobUrl) {
  return NetworkImage(pathOrBlobUrl);
}
