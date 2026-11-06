import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/chat/presentation/providers/chat_providers.dart';
import 'package:hurghada_winners/features/chat/presentation/screens/academy_chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// قائمة محادثات الأكاديمية مع اللاعبين (جهة المدير).
class AcademyConversationsScreen extends ConsumerWidget {
  const AcademyConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(academyConversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(academyConversationsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text('لا توجد محادثات بعد',
                  style: TextStyle(color: AppColors.grey500, fontSize: 15.sp)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(academyConversationsProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(12.r),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = items[i];
                final player = c['player'] as Map<String, dynamic>? ?? {};
                final unread = (c['unread'] as num?)?.toInt() ?? 0;
                final imageUrl = player['image_url'] as String?;
                final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                final lastMsg = c['lastMessage'] as String?;
                final branch = c['academyName'] as String?;
                final time = _formatTime(c['lastMessageAt'] as String?);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage:
                        hasImage ? CachedNetworkImageProvider(imageUrl) : null,
                    child: hasImage
                        ? null
                        : const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(player['fullName'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // اسم الفرع — يرجعه الخادم للسوبر أدمن فقط (محادثات كل الفروع).
                      if (branch != null && branch.isNotEmpty)
                        Text(branch,
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      Text(
                        (lastMsg != null && lastMsg.isNotEmpty)
                            ? lastMsg
                            : 'ابدأ المحادثة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (time.isNotEmpty)
                        Text(time,
                            style: TextStyle(
                                fontSize: 11.sp, color: AppColors.grey500)),
                      if (unread > 0) ...[
                        Gap(4.h),
                        CircleAvatar(
                          radius: 11.r,
                          backgroundColor: AppColors.primary,
                          child: Text(unread > 9 ? '9+' : '$unread',
                              style: TextStyle(
                                  color: AppColors.white, fontSize: 11.sp)),
                        ),
                      ],
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AcademyChatScreen(
                          playerId: player['_id'] as String,
                          playerName: player['fullName'] as String? ?? '',
                        ),
                      ),
                    );
                    ref.invalidate(academyConversationsProvider);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // وقت آخر رسالة: الساعة إن كانت اليوم، "أمس"، وإلا التاريخ.
  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return DateFormat('HH:mm').format(dt);
    if (day == today.subtract(const Duration(days: 1))) return 'أمس';
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}
