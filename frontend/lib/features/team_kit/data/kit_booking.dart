/// حجز طقم فريق.
class KitBooking {
  final String id;
  final String kitName;
  final double price;
  final String currency;
  final String playerId;
  final String playerName;
  final String size;
  final String status; // pending_review | approved | rejected
  final String paymentStatus; // unpaid | paid
  final double paidAmount;
  final String source; // player | manager
  /// إيصال الدفع الذي رفعه اللاعب — فارغ في حجوزات المدير المباشرة.
  final String receiptUrl;
  final DateTime? createdAt;

  const KitBooking({
    required this.id,
    required this.kitName,
    required this.price,
    required this.currency,
    required this.playerId,
    required this.playerName,
    required this.size,
    required this.status,
    required this.paymentStatus,
    required this.paidAmount,
    required this.source,
    required this.receiptUrl,
    required this.createdAt,
  });

  bool get hasReceipt => receiptUrl.isNotEmpty;

  factory KitBooking.fromJson(Map<String, dynamic> json) {
    return KitBooking(
      id: json['_id'] as String? ?? '',
      kitName: json['kitName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EGP',
      playerId: json['playerId'] as String? ?? '',
      playerName: json['playerName'] as String? ?? '',
      size: json['size'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_review',
      paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      source: json['source'] as String? ?? 'player',
      receiptUrl: json['receipt_url'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
