import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/widgets/full_screen_image_viewer.dart';
import 'package:hurghada_winners/features/player/data/player_share_service.dart';
import 'package:hurghada_winners/features/player_videos/data/player_video.dart';
import 'package:hurghada_winners/features/player_videos/presentation/screens/video_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final publicPlayerProfileProvider = FutureProvider.autoDispose
    .family<PublicPlayerProfile, String>((ref, token) {
  return sl<PlayerShareService>().getPublicProfile(token);
});

/// صفحة بروفايل اللاعب العامة (عرض فقط) — تُفتح من رابط المشاركة بدون دخول.
/// أحجام ثابتة (لا screenutil) لأنها تُعرض غالباً على شاشات كمبيوتر عريضة.
class PublicPlayerProfileScreen extends ConsumerWidget {
  final String token;
  const PublicPlayerProfileScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicPlayerProfileProvider(token));
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _Unavailable(),
        data: (p) => _ProfileView(profile: p),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 64, color: AppColors.grey400),
            SizedBox(height: 16),
            Text('هذا الرابط غير متاح',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('ربما تم إيقافه أو استبداله برابط جديد.',
                style: TextStyle(color: AppColors.grey600)),
          ],
        ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final PublicPlayerProfile profile;
  const _ProfileView({required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final hasImage = p.imageUrl != null && p.imageUrl!.isNotEmpty;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── الغلاف + الصورة ──
              SizedBox(
                height: 290,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [AppColors.secondary, AppColors.secondaryDark],
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.academyLogoUrl != null && p.academyLogoUrl!.isNotEmpty)
                                Container(
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: CachedNetworkImage(
                                      imageUrl: p.academyLogoUrl!, fit: BoxFit.contain),
                                ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.academyName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: hasImage ? () => showFullScreenImage(context, p.imageUrl!) : null,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: hasImage
                                  ? CachedNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.person, size: 90, color: AppColors.secondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── الاسم والوسوم ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      p.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (p.sport != null && p.sport!.isNotEmpty)
                          _InfoChip(icon: Icons.sports_tennis_outlined, label: p.sport!),
                        if (p.birthYear != null)
                          _InfoChip(icon: Icons.cake_outlined, label: 'مواليد ${p.birthYear}'),
                        if (p.academyName.isNotEmpty)
                          _InfoChip(icon: Icons.location_on_outlined, label: p.academyName),
                      ],
                    ),
                  ],
                ),
              ),

              // ── النبذة ──
              if (p.bio.isNotEmpty)
                _Section(
                  title: 'نبذة عن اللاعب',
                  icon: Icons.info_outline,
                  child: Text(
                    p.bio,
                    style: const TextStyle(fontSize: 15, height: 1.8, color: AppColors.grey800),
                  ),
                ),

              // ── الصور والفيديوهات (معاً في شبكة واحدة) ──
              if (p.videos.isNotEmpty)
                _Section(
                  title: 'الصور والفيديوهات',
                  icon: Icons.perm_media_outlined,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cols = c.maxWidth > 560 ? 3 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: p.videos.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 16 / 12,
                        ),
                        itemBuilder: (_, i) => _VideoTile(video: p.videos[i]),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 28),
              const Center(
                child: Text('Hurghada Winners',
                    style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey800)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final PlayerVideo video;
  const _VideoTile({required this.video});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openPlayerVideo(context, video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  video.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: video.thumbnailUrl, fit: BoxFit.cover)
                      : Container(color: AppColors.grey200),
                  if (!video.isImage) ...[
                    Container(color: Colors.black.withValues(alpha: 0.2)),
                    const Center(
                      child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
