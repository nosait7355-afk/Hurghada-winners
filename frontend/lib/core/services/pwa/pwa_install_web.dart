// تثبيت التطبيق على الجهاز من المتصفح (PWA).
//
// Chrome/Edge/أندرويد: المتصفح يطلق beforeinstallprompt عندما يرى الموقع
// قابلاً للتثبيت. نحتجز الحدث ونؤجّله حتى يضغط المستخدم زر التثبيت، لأن
// prompt() لا تُقبل إلا استجابةً لإيماءة مستخدم.
//
// iOS Safari: لا يطلق الحدث ولا يوفّر تثبيتاً برمجياً إطلاقاً — الطريق
// الوحيد هو مشاركة ← إضافة إلى الشاشة الرئيسية. لذلك نميّزه بـ
// [needsManualIosSteps] لتعرض الواجهة إرشاداً بدل زر لا يفعل شيئاً.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

class PwaInstall {
  const PwaInstall._();

  static JSObject? _deferredPrompt;
  static bool _installed = false;
  static bool _wired = false;

  static final _listeners = <void Function()>{};

  static void _ensureWired() {
    if (_wired) return;
    _wired = true;

    _installed = _isStandalone();

    web.window.addEventListener(
      'beforeinstallprompt',
      (web.Event e) {
        // بدون preventDefault يعرض المتصفح شريطه الخاص ونفقد الحدث.
        e.preventDefault();
        _deferredPrompt = e as JSObject;
        _notify();
      }.toJS,
    );

    web.window.addEventListener(
      'appinstalled',
      (web.Event _) {
        _deferredPrompt = null;
        _installed = true;
        _notify();
      }.toJS,
    );
  }

  /// التطبيق يعمل من أيقونة على الشاشة الرئيسية لا من تبويب متصفح.
  /// display-mode للمعايير، و navigator.standalone لـ iOS.
  static bool _isStandalone() {
    final standalone =
        web.window.matchMedia('(display-mode: standalone)').matches;
    final iosStandalone =
        web.window.navigator.getProperty<JSBoolean?>('standalone'.toJS)?.toDart;
    return standalone || iosStandalone == true;
  }

  static bool get _isIos {
    final ua = web.window.navigator.userAgent.toLowerCase();
    final isIosDevice = ua.contains('iphone') ||
        ua.contains('ipad') ||
        ua.contains('ipod') ||
        // آيباد على iPadOS 13+ يقدّم نفسه كماك، ونميّزه بوجود لمس.
        (ua.contains('macintosh') && web.window.navigator.maxTouchPoints > 1);
    return isIosDevice;
  }

  /// للواجهة: تختار نص الإرشاد المناسب (Safari مقابل قائمة المتصفح).
  static bool get isIosBrowser {
    _ensureWired();
    return _isIos;
  }

  static bool get isInstalled {
    _ensureWired();
    return _installed;
  }

  /// نعرض الإرشاد اليدوي متى تعذّر فتح نافذة التثبيت برمجياً: على iOS دائماً
  /// (لا تثبيت برمجي هناك)، وحين لم يطلق المتصفح الحدث بعد أو استُهلك —
  /// استدعاء prompt() مرتين على نفس الحدث يرمي استثناءً.
  static bool get needsManualIosSteps {
    _ensureWired();
    if (_installed) return false;
    return _isIos || _deferredPrompt == null;
  }

  /// يظهر الزر على المتصفح ما دام التطبيق غير مثبَّت — لا نشترط أن يكون
  /// المتصفح قد أطلق beforeinstallprompt.
  ///
  /// ربطُ الظهور بذلك الحدث كان يُخفي الزر في الحالة الشائعة: Chrome يؤخّره
  /// ثوانيَ بعد التحميل وقد لا يطلقه أصلاً حسب معاييره، فيبقى الزر غائباً
  /// إلى الأبد. الآن يظهر دائماً؛ والضغط يفتح النافذة إن كان الحدث متاحاً،
  /// وإلّا يشرح الخطوات اليدوية — وكلاهما يوصّل المستخدم للتثبيت.
  static bool get canInstall {
    _ensureWired();
    return !_installed;
  }

  static void addListener(void Function() listener) {
    _ensureWired();
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) =>
      _listeners.remove(listener);

  static void _notify() {
    for (final l in _listeners.toList()) {
      l();
    }
  }

  static Future<void> promptInstall() async {
    final prompt = _deferredPrompt;
    if (prompt == null) return;
    // الحدث يُستهلك بعد أول عرض؛ المتصفح يطلقه من جديد إن بقي الموقع
    // قابلاً للتثبيت، فنُفرغه هنا حتى لا نستدعيه مرتين.
    _deferredPrompt = null;
    _notify();
    try {
      prompt.callMethod<JSPromise>('prompt'.toJS);
    } catch (_) {
      // بعض المتصفحات ترفض prompt() خارج إيماءة المستخدم — نتجاهل بصمت،
      // فالزر سيعود للظهور عند إطلاق الحدث مجدداً.
    }
  }
}
