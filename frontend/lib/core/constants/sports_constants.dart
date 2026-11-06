/// Default suggested sports and the weekly attendance days.
///
/// Sports are an open list — academies may store any sport string, these are
/// only the defaults offered in the multi-select. New sports can be added
/// without changing the backend (the `sports` field is a free string array).
class SportsConstants {
  SportsConstants._();

  static const List<String> defaultSports = [
    'Tennis',
  ];

  /// Emoji shown next to a sport name (e.g. in the grouped Groups screen).
  /// Sports are free strings, so unknown values fall back to a neutral medal.
  static const Map<String, String> _sportEmojis = {
    'كرة قدم': '⚽',
    'كرة سلة': '🏀',
    'كرة طائرة': '🏐',
    'كرة يد': '🤾',
    'سباحة': '🏊',
    'كاراتيه': '🥋',
    'Tennis': '🎾',
    'تنس': '🎾',
    'جمباز': '🤸',
    'ملاكمة': '🥊',
    'جري': '🏃',
  };

  static String sportEmoji(String? sport) {
    if (sport == null) return '🏅';
    return _sportEmojis[sport.trim()] ?? '🏅';
  }

  /// Weekly attendance days (Saturday-first, matching the local week).
  static const List<String> weekDays = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];
}
