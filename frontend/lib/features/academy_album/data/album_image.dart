/// عنصر صورة في ألبوم الأكاديمية. نموذج بسيط (نص خالص + رابط صورة Cloudinary).
class AlbumImage {
  final String id;
  final String academyId;
  final String title;
  final String description;
  final String imageUrl;
  final int order;

  const AlbumImage({
    required this.id,
    required this.academyId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.order,
  });

  factory AlbumImage.fromJson(Map<String, dynamic> json) {
    return AlbumImage(
      id: json['_id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
