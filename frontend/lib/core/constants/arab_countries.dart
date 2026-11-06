/// دولة عربية مع رمز الاتصال الدولي وعملتها — المصدر الموحّد لكود الأرقام
/// والعملة داخل التطبيق. اختيار الدولة عند تسجيل الأكاديمية يحدّد تلقائياً:
/// (1) كود الدولة الذي يُضاف لأرقام الهاتف/واتساب، و(2) عملة الأكاديمية.
class ArabCountry {
  final String nameAr;
  final String dialCode; // أرقام فقط بدون +، مثل '20'
  final String flag; // إيموجي العلم
  final String currencyCode; // رمز العملة ISO، مثل 'EGP'

  const ArabCountry(this.nameAr, this.dialCode, this.flag, this.currencyCode);

  /// نص مختصر يظهر في القائمة: العلم + الكود، مثل "🇪🇬 +20".
  String get shortLabel => '$flag +$dialCode';

  /// نص كامل يظهر داخل القائمة المنسدلة: العلم + الاسم + الكود.
  String get fullLabel => '$flag  $nameAr (+$dialCode)';
}

/// نتيجة فصل رقم دولي مخزَّن إلى دولته وجزئه المحلي.
class SplitNumber {
  final ArabCountry country;
  final String local;
  const SplitNumber(this.country, this.local);
}

/// كل دول جامعة الدول العربية (22 دولة) مرتبة بالكود الدولي، مع عملة كل دولة.
const List<ArabCountry> arabCountries = [
  ArabCountry('مصر', '20', '🇪🇬', 'EGP'),
  ArabCountry('المغرب', '212', '🇲🇦', 'MAD'),
  ArabCountry('الجزائر', '213', '🇩🇿', 'DZD'),
  ArabCountry('تونس', '216', '🇹🇳', 'TND'),
  ArabCountry('ليبيا', '218', '🇱🇾', 'LYD'),
  ArabCountry('موريتانيا', '222', '🇲🇷', 'MRU'),
  ArabCountry('السودان', '249', '🇸🇩', 'SDG'),
  ArabCountry('الصومال', '252', '🇸🇴', 'SOS'),
  ArabCountry('جيبوتي', '253', '🇩🇯', 'DJF'),
  ArabCountry('جزر القمر', '269', '🇰🇲', 'KMF'),
  ArabCountry('لبنان', '961', '🇱🇧', 'LBP'),
  ArabCountry('الأردن', '962', '🇯🇴', 'JOD'),
  ArabCountry('سوريا', '963', '🇸🇾', 'SYP'),
  ArabCountry('العراق', '964', '🇮🇶', 'IQD'),
  ArabCountry('الكويت', '965', '🇰🇼', 'KWD'),
  ArabCountry('السعودية', '966', '🇸🇦', 'SAR'),
  ArabCountry('اليمن', '967', '🇾🇪', 'YER'),
  ArabCountry('عُمان', '968', '🇴🇲', 'OMR'),
  ArabCountry('فلسطين', '970', '🇵🇸', 'ILS'),
  ArabCountry('الإمارات', '971', '🇦🇪', 'AED'),
  ArabCountry('البحرين', '973', '🇧🇭', 'BHD'),
  ArabCountry('قطر', '974', '🇶🇦', 'QAR'),
];

/// الدولة الافتراضية (مصر) — تتوافق مع العملة الافتراضية للأكاديميات.
const ArabCountry arabCountryDefault = ArabCountry('مصر', '20', '🇪🇬', 'EGP');

/// أول دولة تُطابق رمز العملة المعطى (لعكس الاختيار في شاشات التعديل)، أو null.
ArabCountry? countryByCurrency(String? currencyCode) {
  if (currencyCode == null || currencyCode.isEmpty) return null;
  for (final c in arabCountries) {
    if (c.currencyCode == currencyCode) return c;
  }
  return null;
}

/// يبني رقماً دولياً من كود الدولة + الرقم المحلي:
/// يُزيل كل ما ليس رقماً من المحلي ويحذف صفر البداية (بادئة وطنية)، ثم يسبقه
/// بكود الدولة. يعيد سلسلة فارغة إذا لم يُدخَل رقم محلي.
String buildInternationalNumber(ArabCountry country, String localRaw) {
  var local = localRaw.replaceAll(RegExp(r'[^\d]'), '');
  local = local.replaceFirst(RegExp(r'^0+'), '');
  if (local.isEmpty) return '';
  return '+${country.dialCode}$local';
}

/// يفصل رقماً دولياً مخزَّناً إلى دولته وجزئه المحلي. يجرّب أطول الأكواد أولاً
/// لتفادي تطابق '20' قبل '212'. عند تعذّر التعرّف يعيد الدولة الافتراضية.
SplitNumber splitStoredNumber(String stored) {
  final digits = stored.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return const SplitNumber(arabCountryDefault, '');

  final sorted = [...arabCountries]
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
  for (final c in sorted) {
    if (digits.startsWith(c.dialCode) && digits.length > c.dialCode.length) {
      return SplitNumber(c, digits.substring(c.dialCode.length));
    }
  }
  return SplitNumber(arabCountryDefault, digits);
}
