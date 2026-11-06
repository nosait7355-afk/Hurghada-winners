import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/player/data/join_request_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// عدد طلبات الانضمام المعلّقة لأكاديمية معيّنة — تُستخدم لعرض شارة العدّاد
/// أعلى صفحة اللاعبين والداشبورد. إضافية بالكامل.
final joinRequestsCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, academyId) async {
  final list = await sl<JoinRequestService>().list(academyId: academyId);
  return list.length;
});

/// أيقونة "طلبات الانضمام" بشارة عدّاد — نفس نمط NotificationBellIcon
/// بالضبط، تظهر أعلى صفحة اللاعبين (موبايل/ديسكتوب) لكل من الأدمن والمشرف.
class JoinRequestsBadgeIcon extends ConsumerWidget {
  final String academyId;
  final VoidCallback onTap;
  const JoinRequestsBadgeIcon({super.key, required this.academyId, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(joinRequestsCountProvider(academyId)).valueOrNull ?? 0;
    return IconButton(
      onPressed: onTap,
      tooltip: 'طلبات الانضمام',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          count > 9 ? '9+' : '$count',
          style: TextStyle(fontSize: 10.sp, color: Colors.white),
        ),
        backgroundColor: AppColors.warning,
        child: const Icon(Icons.person_add_alt_1_outlined),
      ),
    );
  }
}
