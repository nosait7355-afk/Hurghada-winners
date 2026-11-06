import 'package:hurghada_winners/features/team_kit/data/kit_booking.dart';

/// المقاسات الثابتة المتاحة لطقم الفريق — من 5XS إلى 5XL. مطابقة للخادم
/// (backend/src/utils/kitSizes.js).
const List<String> kKitSizes = [
  '5XS', '4XS', '3XS', '2XS', 'XS',
  'S', 'M', 'L', 'XL',
  '2XL', '3XL', '4XL', '5XL',
];

/// طقم الفريق: نسخة واحدة فعّالة لكل أكاديمية.
class TeamKit {
  final String id;
  final String academyId;
  final String name;
  final double price;
  final String imageUrl;
  final List<String> availableSizes;

  /// آخر حجز للاعب الحالي على هذا الطقم (جهة اللاعب فقط).
  final KitBooking? myBooking;

  const TeamKit({
    required this.id,
    required this.academyId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.availableSizes,
    this.myBooking,
  });

  factory TeamKit.fromJson(Map<String, dynamic> json) {
    return TeamKit(
      id: json['_id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      availableSizes: (json['availableSizes'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      myBooking: json['myBooking'] is Map<String, dynamic>
          ? KitBooking.fromJson(json['myBooking'] as Map<String, dynamic>)
          : null,
    );
  }
}
