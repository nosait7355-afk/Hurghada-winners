import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/chat/presentation/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أيقونة الرسائل مع Badge مستقل — نظير NotificationBellIcon تماماً، لكن
/// عدّادها من academyMessagesUnreadProvider (مجموع unread للمحادثات)، منفصل
/// كلياً عن عدّاد مركز الإشعارات. لجهة مدير الأكاديمية فقط.
class MessagesChatIcon extends ConsumerWidget {
  final VoidCallback onTap;
  const MessagesChatIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(academyMessagesUnreadProvider);
    return IconButton(
      onPressed: onTap,
      tooltip: 'الرسائل',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(
          unread > 9 ? '9+' : '$unread',
          style: TextStyle(fontSize: 10.sp, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
