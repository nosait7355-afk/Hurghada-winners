/// استخراج كود اللاعب من محتوى الـ QR أو الإدخال اليدوي.
///
/// نفس منطق normalizeCode في الخادم:
///   "PLAYER:Y-0145"  →  "Y-0145"  (البادئة غير حسّاسة لحالة الأحرف)
///   "y-0145"         →  "Y-0145"
///   "145" / "0145"   →  "Y-0145"  (أرقام فقط ⇒ padLeft(4, '0'))
///   " Y-0145 "       →  "Y-0145"
class PlayerQr {
  PlayerQr._();

  static const String prefix = 'PLAYER:';

  static final RegExp _digits = RegExp(r'^(?:Y-?)?(\d+)$', caseSensitive: false);

  static String extractCode(String raw) {
    var value = raw.trim();
    if (value.toUpperCase().startsWith(prefix)) {
      value = value.substring(prefix.length).trim();
    }
    final m = _digits.firstMatch(value);
    if (m != null) {
      return 'Y-${int.parse(m.group(1)!).toString().padLeft(4, '0')}';
    }
    return value;
  }
}
