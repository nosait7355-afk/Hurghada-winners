// أندرويد/iOS الأصلية: التطبيق مثبَّت أصلاً، فلا زر تثبيت.
// الواجهة تطابق النسخة الويب حتى يبقى نداء المستدعي واحداً.
class PwaInstall {
  const PwaInstall._();

  /// هل يمكن عرض زر التثبيت؟ دائماً false خارج المتصفح.
  static bool get canInstall => false;

  /// هل يعمل التطبيق مثبَّتاً على الجهاز؟ لا معنى لها خارج المتصفح.
  static bool get isInstalled => false;

  /// متصفح iOS لا يدعم التثبيت البرمجي — يحتاج إرشاد المستخدم يدوياً.
  static bool get needsManualIosSteps => false;

  /// تختار الواجهة نص الإرشاد بناءً عليها. بلا معنى خارج المتصفح.
  static bool get isIosBrowser => false;

  /// يُستدعى عند تغيّر حالة التثبيت حتى تعيد الواجهة البناء.
  static void addListener(void Function() listener) {}
  static void removeListener(void Function() listener) {}

  static Future<void> promptInstall() async {}
}
