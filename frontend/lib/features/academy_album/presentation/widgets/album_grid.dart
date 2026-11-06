import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/academy_album/data/album_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شبكة صور الألبوم مع تحميل كسول (CachedNetworkImage) وتحميل صفحات إضافية
/// عند الاقتراب من النهاية. مشتركة بين المدير واللاعب.
class AlbumGrid extends StatefulWidget {
  final List<AlbumImage> items;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final void Function(int index) onTapImage;
  // إجراءات المدير الاختيارية (تظهر كأزرار فوق كل صورة).
  final void Function(AlbumImage image)? onEdit;
  final void Function(AlbumImage image)? onDelete;

  const AlbumGrid({
    super.key,
    required this.items,
    required this.loadingMore,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onTapImage,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<AlbumGrid> createState() => _AlbumGridState();
}

class _AlbumGridState extends State<AlbumGrid> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1100 ? 5 : (width >= 700 ? 4 : 2);
    final manage = widget.onEdit != null || widget.onDelete != null;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: GridView.builder(
        controller: _scroll,
        padding: EdgeInsets.all(12.r),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 8.r,
          mainAxisSpacing: 8.r,
        ),
        itemCount: widget.items.length + (widget.loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= widget.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final img = widget.items[i];
          return GestureDetector(
            onTap: () => widget.onTapImage(i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: img.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.grey200),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.grey200,
                      child: const Icon(Icons.broken_image, color: AppColors.grey500),
                    ),
                  ),
                  if (img.title.isNotEmpty)
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.r, vertical: 4.r),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          img.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 11.sp),
                        ),
                      ),
                    ),
                  if (manage)
                    PositionedDirectional(
                      top: 2.r,
                      end: 2.r,
                      // mainAxisSize.min وإلا تمدّد الصفّ على عرض البطاقة
                      // كاملاً وابتعدت الأزرار عن الحافة.
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onEdit != null)
                            _iconBtn(Icons.edit, () => widget.onEdit!(img)),
                          if (widget.onDelete != null)
                            _iconBtn(Icons.delete, () => widget.onDelete!(img)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(left: 2.r),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 15.sp),
        ),
      ),
    );
  }
}
