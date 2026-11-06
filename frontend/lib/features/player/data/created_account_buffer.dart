/// حاملة مؤقتة لبيانات حساب اللاعب المُنشأ حديثاً (username/password) — تُعرض
/// مرة واحدة فقط بعد إنشاء اللاعب. الـ datasource يملؤها، وشاشة الإضافة
/// تقرؤها ثم تمسحها. حل معزول يتجنّب تمرير الحقل عبر طبقات clean-architecture.
class CreatedAccountBuffer {
  CreatedAccountBuffer._();

  static Map<String, dynamic>? _last;

  static void set(Map<String, dynamic>? account) => _last = account;

  /// يعيد آخر حساب ويمسحه (استهلاك لمرة واحدة).
  static Map<String, dynamic>? take() {
    final v = _last;
    _last = null;
    return v;
  }
}
