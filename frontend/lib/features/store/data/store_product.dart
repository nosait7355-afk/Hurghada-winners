/// منتج في متجر الأكاديمية. نموذج بسيط (نص + سعر + رابط صورة Cloudinary).
class StoreProduct {
  final String id;
  final String academyId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final int order;

  const StoreProduct({
    required this.id,
    required this.academyId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.order,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['_id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
