import 'dart:io';

import 'package:hurghada_winners/core/utils/image_compress.dart';
import 'package:dio/dio.dart';

/// كل رفع صور في التطبيق يمر من هنا، فالتصغير التلقائي (تحت حد 2MB) يُطبَّق
/// في مكان واحد على كل الشاشات.
Future<MultipartFile> buildImageMultipart(
  String pathOrBlobUrl, {
  required String filename,
}) async {
  final file = File(pathOrBlobUrl);
  if (await file.length() <= kUploadTargetBytes) {
    return MultipartFile.fromFile(pathOrBlobUrl, filename: filename);
  }
  final bytes = await shrinkImageForUpload(await file.readAsBytes());
  return MultipartFile.fromBytes(bytes, filename: filename);
}
