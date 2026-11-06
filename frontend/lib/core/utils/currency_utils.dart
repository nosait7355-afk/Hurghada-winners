/// Maps an academy currency code to its Arabic label.
///
/// The currency is derived from the academy's country (see `arab_countries.dart`).
/// Covers every Arab League currency, plus USD for legacy/flexibility.
/// Falls back to the Egyptian pound for unknown / legacy values.
class CurrencyUtils {
  CurrencyUtils._();

  static const String defaultCode = 'EGP';

  // تسمية مختصرة تظهر بجانب الأسعار في كل التطبيق، مثل "100 جنيه".
  static const Map<String, String> _labels = {
    'EGP': 'جنيه',
    'SAR': 'ريال',
    'AED': 'درهم',
    'KWD': 'دينار',
    'QAR': 'ريال',
    'BHD': 'دينار',
    'OMR': 'ريال',
    'JOD': 'دينار',
    'LBP': 'ليرة',
    'SYP': 'ليرة',
    'IQD': 'دينار',
    'ILS': 'شيكل',
    'YER': 'ريال',
    'LYD': 'دينار',
    'TND': 'دينار',
    'DZD': 'دينار',
    'MAD': 'درهم',
    'MRU': 'أوقية',
    'SDG': 'جنيه',
    'SOS': 'شلن',
    'DJF': 'فرنك',
    'KMF': 'فرنك',
    'USD': 'دولار',
  };

  /// Supported currency codes (used to build dropdowns).
  static const List<String> codes = [
    'EGP', 'SAR', 'AED', 'KWD', 'QAR', 'BHD', 'OMR', 'JOD', 'LBP', 'SYP',
    'IQD', 'ILS', 'YER', 'LYD', 'TND', 'DZD', 'MAD', 'MRU', 'SDG', 'SOS',
    'DJF', 'KMF', 'USD',
  ];

  /// Arabic label for a currency code, e.g. 'EGP' → 'جنيه'.
  static String label(String? code) {
    if (code == null) return _labels[defaultCode]!;
    return _labels[code] ?? _labels[defaultCode]!;
  }

  /// Label including the code for selectors, e.g. 'جنيه (EGP)'.
  static String labelWithCode(String code) => '${label(code)} ($code)';
}
