import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/presentation/providers/player_provider.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_detail_screen.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

const List<String> _arabicMonthNames = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// شاشة "أعياد الميلاد" — 3 تبويبات: الشهر الماضي / الحالي / القادم، وكل
/// تبويب يعرض لاعبي الأكاديمية المولودين في ذلك الشهر مرتّبين حسب اليوم.
class PlayerBirthdaysScreen extends StatelessWidget {
  final String academyId;
  const PlayerBirthdaysScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context) {
    final current = DateTime.now().month; // 1..12
    final prev = current == 1 ? 12 : current - 1;
    final next = current == 12 ? 1 : current + 1;
    final months = [prev, current, next];
    const labels = ['الشهر الماضي', 'الشهر الحالي', 'الشهر القادم'];

    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('أعياد الميلاد'),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              for (var i = 0; i < 3; i++)
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(labels[i], style: TextStyle(fontSize: 11.sp)),
                      Text(_arabicMonthNames[months[i] - 1],
                          style: TextStyle(
                              fontSize: 13.sp, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final m in months)
              _MonthBirthdays(academyId: academyId, month: m),
          ],
        ),
      ),
    );
  }
}

class _MonthBirthdays extends ConsumerWidget {
  final String academyId;
  final int month;
  const _MonthBirthdays({required this.academyId, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (academyId: academyId, month: month);
    final birthdaysAsync = ref.watch(playerBirthdaysProvider(key));
    final monthName = _arabicMonthNames[month - 1];

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(playerBirthdaysProvider(key)),
      child: birthdaysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(40.r),
              child: const Center(
                child: Text(
                  'تعذّر تحميل أعياد الميلاد',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
        data: (players) {
          if (players.isEmpty) {
            return ListView(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 80.h),
                  child: Column(
                    children: [
                      Icon(Icons.cake_outlined,
                          size: 56.sp, color: AppColors.grey300),
                      Gap(12.h),
                      Text(
                        'لا يوجد لاعبون عيد ميلادهم في $monthName',
                        style: TextStyle(
                            color: AppColors.grey500, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(16.r),
            itemCount: players.length,
            separatorBuilder: (_, __) => Gap(10.h),
            itemBuilder: (context, index) =>
                _BirthdayCard(player: players[index]),
          );
        },
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  final PlayerEntity player;
  const _BirthdayCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final day = player.birthDate.day;
    final isToday = DateTime.now().day == day &&
        DateTime.now().month == player.birthDate.month;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border:
            isToday ? Border.all(color: AppColors.warning, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26.r,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage:
                player.imageUrl != null ? NetworkImage(player.imageUrl!) : null,
            child: player.imageUrl == null
                ? Icon(Icons.cake_outlined,
                    color: AppColors.primary, size: 24.sp)
                : null,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.fullName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                Gap(2.h),
                Text(
                  DateFormat('d MMMM', 'ar').format(player.birthDate),
                  style: TextStyle(fontSize: 12.sp, color: AppColors.grey600),
                ),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'النهاردة 🎉',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ),
          Gap(6.w),
          IconButton(
            onPressed: () => WhatsAppUtils.open(
              player.parentPhone,
              message:
                  'كل سنة وحضرتك طيب! 🎂 عيد ميلاد سعيد لـ ${player.fullName}',
            ),
            icon: Icon(Icons.chat_bubble_outline,
                color: AppColors.success, size: 20.sp),
            tooltip: 'تهنئة عبر واتساب',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PlayerDetailScreen(
                playerId: player.id,
                academyId: player.academyId,
              ),
            )),
            icon: Icon(Icons.person_outline,
                color: AppColors.primary, size: 20.sp),
            tooltip: 'صفحة اللاعب',
          ),
        ],
      ),
    );
  }
}
