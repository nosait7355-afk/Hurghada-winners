import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/player_videos/presentation/providers/player_video_providers.dart';
import 'package:hurghada_winners/features/player_videos/presentation/widgets/videos_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// فيديوهاتي — جهة اللاعب: مشاهدة + إعجاب + تعليق.
/// الإضافة والتعديل والحذف من صلاحيات الأكاديمية وحدها.
class MyVideosScreen extends ConsumerWidget {
  const MyVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myVideosProvider);
    final notifier = ref.read(myVideosProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('فيديوهاتي')),
      body: VideosBody(
        state: state,
        emptyText: 'لم تُضِف الأكاديمية فيديوهات لك بعد',
        actions: VideoActions(
          service: ref.read(playerVideoServiceProvider),
          notifier: notifier,
          isAcademy: false,
        ),
      ),
    );
  }
}
