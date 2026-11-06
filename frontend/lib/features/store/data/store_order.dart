/// طلب شراء في متجر الأكاديمية (جهة المدير). لقطة اسم المنتج/السعر وقت الطلب.
class StoreOrder {
  final String id;
  final String productName;
  final double price;
  final String currency;
  final String playerName;
  final String academyName; // فرع اللاعب
  final String status; // pending | contacted | completed | cancelled
  final DateTime? createdAt;

  const StoreOrder({
    required this.id,
    required this.productName,
    required this.price,
    required this.currency,
    required this.playerName,
    this.academyName = '',
    required this.status,
    required this.createdAt,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    return StoreOrder(
      id: json['_id'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EGP',
      playerName: json['playerName'] as String? ?? '',
      academyName: json['academyName'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
