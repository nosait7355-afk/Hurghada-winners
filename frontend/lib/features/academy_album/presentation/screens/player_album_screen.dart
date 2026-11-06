import 'package:hurghada_winners/features/academy_album/presentation/providers/album_providers.dart';
import 'package:hurghada_winners/features/academy_album/presentation/screens/academy_album_screen.dart';
import 'package:hurghada_winners/features/academy_album/presentation/screens/album_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ألبوم الأكاديمية — جهة اللاعب: عرض/تكبير/سحب/مشاركة/حفظ فقط.
/// لا رفع ولا تعديل ولا حذف. يرى صور أكاديميته حصراً (يُفرَض في الخادم).
class PlayerAlbumScreen extends ConsumerWidget {
  const PlayerAlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerAlbumProvider);
    final notifier = ref.read(playerAlbumProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('ألبوم الأكاديمية')),
      body: AlbumBody(
        state: state,
        onRetry: notifier.refresh,
        onRefresh: notifier.refresh,
        onLoadMore: notifier.loadMore,
        onTapImage: (i) => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AlbumViewerScreen(images: state.items, initialIndex: i),
        )),
      ),
    );
  }
}
