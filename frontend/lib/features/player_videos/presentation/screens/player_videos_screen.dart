import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';
import 'package:hurghada_winners/features/player_videos/presentation/dialogs/video_form_dialog.dart';
import 'package:hurghada_winners/features/player_videos/presentation/providers/player_video_providers.dart';
import 'package:hurghada_winners/features/player_videos/presentation/widgets/videos_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// فيديوهات بروفايل لاعب — جهة الإدارة: إضافة رابط + تعديل + حذف + تفاعل.
class PlayerVideosScreen extends ConsumerWidget {
  final String playerId;
  final String playerName;

  const PlayerVideosScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  /// اختيار نوع الإضافة: صورة أو فيديو.
  Future<void> _chooseAdd(BuildContext context, WidgetRef ref) async {
    final kind = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined),
              title: const Text('صورة'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.add_link),
              title: const Text('فيديو (رابط YouTube / Drive)'),
              onTap: () => Navigator.pop(ctx, 'video'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (kind == 'image') {
      await _addImage(context, ref);
    } else if (kind == 'video') {
      await _add(context, ref);
    }
  }

  Future<void> _addImage(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (img == null || !context.mounted) return;
    final res = await showDialog<VideoFormResult>(
      context: context,
      builder: (_) => const VideoFormDialog(imageMode: true),
    );
    if (res == null) return;
    try {
      await ref.read(adminVideoServiceProvider).createImage(
            playerId: playerId,
            imagePath: img.path,
            title: res.title,
            description: res.description,
          );
      ref.read(academyPlayerVideosProvider(playerId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تمت إضافة الصورة بنجاح'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(videoErrorMessage(e, fallback: 'تعذّر رفع الصورة. حاول مرة أخرى.')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<VideoFormResult>(
      context: context,
      builder: (_) => const VideoFormDialog(),
    );
    if (res == null) return;
    try {
      await ref.read(adminVideoServiceProvider).create(
            playerId: playerId,
            title: res.title,
            url: res.url,
            description: res.description,
          );
      ref.read(academyPlayerVideosProvider(playerId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تمت إضافة الفيديو بنجاح'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(videoErrorMessage(e, fallback: 'تعذّرت الإضافة. حاول مرة أخرى.')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, PlayerVideo video) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<VideoFormResult>(
      context: context,
      builder: (_) => VideoFormDialog(existing: video),
    );
    if (res == null) return;
    try {
      await ref.read(adminVideoServiceProvider).update(
            id: video.id,
            title: res.title,
            description: res.description,
            url: video.isImage ? null : res.url,
          );
      ref.read(academyPlayerVideosProvider(playerId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم تحديث الفيديو'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(videoErrorMessage(e, fallback: 'تعذّر التحديث.')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, PlayerVideo video) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('حذف الفيديو'),
        content: const Text('سيُحذف العنصر وكل تعليقاته نهائياً. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminVideoServiceProvider).delete(video.id);
      ref.read(academyPlayerVideosProvider(playerId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم حذف الفيديو'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(videoErrorMessage(e, fallback: 'تعذّر الحذف.')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(academyPlayerVideosProvider(playerId));
    final notifier = ref.read(academyPlayerVideosProvider(playerId).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('صور وفيديوهات اللاعب'),
        bottom: playerName.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(22),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    playerName,
                    style: const TextStyle(fontSize: 13, color: AppColors.white),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _chooseAdd(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة صورة / فيديو'),
      ),
      body: VideosBody(
        state: state,
        emptyText: 'لا توجد صور أو فيديوهات بعد',
        actions: VideoActions(
          service: ref.read(adminVideoServiceProvider),
          notifier: notifier,
          isAcademy: true,
        ),
        onEdit: (v) => _edit(context, ref, v),
        onDelete: (v) => _delete(context, ref, v),
      ),
    );
  }
}
