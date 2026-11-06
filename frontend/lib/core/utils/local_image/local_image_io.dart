import 'dart:io';

import 'package:flutter/widgets.dart';

// على الموبايل والديسكتوب `XFile.path` مسار حقيقي في نظام الملفات.
ImageProvider pickedImageProvider(String pathOrBlobUrl) {
  return FileImage(File(pathOrBlobUrl));
}
