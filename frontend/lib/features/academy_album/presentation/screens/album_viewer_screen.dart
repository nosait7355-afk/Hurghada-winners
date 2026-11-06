import 'package:hurghada_winners/features/academy_album/data/album_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// عارض ملء الشاشة: تكبير (InteractiveViewer) + سحب بين الصور (PageView) +
/// مشاركة/حفظ عبر share_plus. مشترك بين المدير واللاعب.
class AlbumViewerScreen extends StatefulWidget {
  final List<AlbumImage> images;
  final int initialIndex;

  const AlbumViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<AlbumViewerScreen> createState() => _AlbumViewerScreenState();
}

class _AlbumViewerScreenState extends State<AlbumViewerScreen> {
  late final PageController _controller;
  late int _index;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final img = widget.images[_index];
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (kIsWeb) {
        // على الويب لا نظام ملفات محلي — نشارك الرابط.
        await Share.share(img.imageUrl, subject: img.title);
      } else {
        // نزّل الصورة إلى ملف مؤقت ثم شاركها كملف (يتيح "حفظ الصورة" من ورقة
        // المشاركة). يعيد استخدام dio وpath_provider الموجودين — لا تبعية جديدة.
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/album_${img.id}.jpg';
        await Dio().download(img.imageUrl, path);
        await Share.shareXFiles([XFile(path)], text: img.title);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذّرت المشاركة. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.images[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
        actions: [
          IconButton(
            tooltip: 'مشاركة',
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final it = widget.images[i];
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: it.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    ),
                  ),
                );
              },
            ),
          ),
          if (img.title.isNotEmpty || img.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (img.title.isNotEmpty)
                    Text(img.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  if (img.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(img.description,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
