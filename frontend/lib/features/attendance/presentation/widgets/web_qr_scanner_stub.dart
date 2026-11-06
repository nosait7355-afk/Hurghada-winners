// Non-web fallback. Never reached because callers gate on kIsWeb, but keeps
// the conditional-import API compilable on Android/Windows.
import 'package:flutter/widgets.dart';

Future<String?> showWebQrScanner(BuildContext context) async {
  throw UnsupportedError('Web QR scanner is only available on web');
}
