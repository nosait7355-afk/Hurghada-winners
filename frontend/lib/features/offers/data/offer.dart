/// عرض / خصم. [academyIds] فارغة = كل الفروع.
class Offer {
  final String id;
  final String title;
  final String details;
  final String? imageUrl;

  /// 'percent' | 'amount' | null
  final String? discountType;
  final double? discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> academyIds;
  final List<String> academyNames;
  final bool isActive;

  /// هل يملك المستخدم الحالي تعديله (يحدده الخادم).
  final bool canEdit;

  const Offer({
    required this.id,
    required this.title,
    required this.details,
    this.imageUrl,
    this.discountType,
    this.discountValue,
    required this.startDate,
    required this.endDate,
    this.academyIds = const [],
    this.academyNames = const [],
    this.isActive = true,
    this.canEdit = false,
  });

  bool get forAllBranches => academyIds.isEmpty;

  /// التواريخ مخزّنة منتصف ليل UTC — نقارن بالتاريخ فقط.
  bool get isRunning {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return isActive && !today.isBefore(startDate) && !today.isAfter(endDate);
  }

  bool get isEnded {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).isAfter(endDate);
  }

  /// "خصم 20%" أو "خصم 150 ج.م" أو null.
  String? get discountLabel {
    final v = discountValue;
    if (discountType == null || v == null) return null;
    final n = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    return discountType == 'percent' ? 'خصم $n%' : 'خصم $n ج.م';
  }

  static DateTime _day(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toUtc() ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: j['_id'] as String,
        title: j['title'] as String? ?? '',
        details: j['details'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
        discountType: j['discountType'] as String?,
        discountValue: (j['discountValue'] as num?)?.toDouble(),
        startDate: _day(j['startDate']),
        endDate: _day(j['endDate']),
        academyIds: ((j['academyIds'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        academyNames: ((j['academyNames'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        isActive: j['isActive'] as bool? ?? true,
        canEdit: j['canEdit'] as bool? ?? false,
      );
}
