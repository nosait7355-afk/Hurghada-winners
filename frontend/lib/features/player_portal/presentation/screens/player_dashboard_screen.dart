import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/offers/presentation/providers/offers_providers.dart';
import 'package:hurghada_winners/features/offers/presentation/widgets/player_offers_strip.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:hurghada_winners/features/player_portal/presentation/screens/player_renewal_request_screen.dart';
import 'package:hurghada_winners/features/player_portal/presentation/widgets/my_share_sheet.dart';
import 'package:hurghada_winners/features/player_portal/presentation/widgets/player_photo_sheet.dart';
import 'package:hurghada_winners/features/player_portal/presentation/widgets/switch_account_sheet.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// لوحة اللاعب — تحية + تنبيه اشتراك + إحصائيات سريعة + إجراءات سريعة
/// (المتجر/الألبوم) + جدول التدريب (مع تمييز اليوم) + الحضور + التقييمات،
/// مع وصول سريع للمحادثة والإشعارات (بعدّادات غير المقروء).
class PlayerDashboardScreen extends ConsumerWidget {
  const PlayerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(playerDashboardProvider);
    final data = dashAsync.valueOrNull;
    final unreadNotif =
        ((data?['notifications'] as Map?)?['unread'] as num?)?.toInt() ?? 0;
    final unreadChat = ((data?['chat'] as Map?)?['unread'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة اللاعب'),
        actions: [
          const SwitchAccountButton(),
          Badge.count(
            count: unreadNotif,
            isLabelVisible: unreadNotif > 0,
            child: IconButton(
              tooltip: 'الإشعارات',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push(AppRoutes.playerNotifications),
            ),
          ),
          Badge.count(
            count: unreadChat,
            isLabelVisible: unreadChat > 0,
            child: IconButton(
              tooltip: 'المحادثة',
              icon: const Icon(Icons.chat_outlined),
              onPressed: () => context.push(AppRoutes.playerChat),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'المزيد',
            onSelected: (value) async {
              switch (value) {
                case 'share':
                  final player = data?['player'] as Map<String, dynamic>?;
                  await showMySharePageSheet(context,
                      playerName: player?['fullName'] as String?);
                case 'support':
                  await WhatsAppUtils.openSupport(context);
                case 'logout':
                  await ref.read(playerSessionProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.welcome);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('مشاركة صفحتي'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'support',
                child: ListTile(
                  leading: Icon(Icons.support_agent, color: Color(0xFF25D366)),
                  title: Text('الدعم الفني'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('تسجيل الخروج'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              Gap(12.h),
              const Text('تعذّر تحميل البيانات'),
              Gap(12.h),
              ElevatedButton(
                onPressed: () => ref.invalidate(playerDashboardProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (data) {
          final sub = data['subscription'] as Map<String, dynamic>?;
          final attendance = data['attendance'] as Map<String, dynamic>?;
          final latestEval = data['latestEvaluation'] as Map<String, dynamic>?;
          final evals = (data['evaluations'] as List<dynamic>?) ?? const [];
          final alert = _subscriptionAlert(
            context,
            sub,
            data['renewalRequest'] as Map<String, dynamic>?,
          );

          return RefreshIndicator(
            onRefresh: () async => ref
              ..invalidate(playerDashboardProvider)
              ..invalidate(playerOffersProvider),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                _header(context, ref, data['player'] as Map<String, dynamic>?),
                Gap(16.h),
                _socialLinksCard(context, ref),
                if (alert != null) ...[alert, Gap(16.h)],
                _statsRow(sub, attendance, latestEval),
                Gap(16.h),
                const PlayerOffersStrip(),
                _quickActions(context),
                Gap(16.h),
                _scheduleCard(data['schedule'] as Map<String, dynamic>?),
                Gap(16.h),
                _attendanceCard(attendance),
                Gap(16.h),
                _evaluationCard(evals, latestEval),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── روابط التواصل الاجتماعي للأكاديمية (تظهر فقط إن كانت مضبوطة) ──
  Widget _socialLinksCard(BuildContext context, WidgetRef ref) {
    final sessionPlayer = ref.watch(playerSessionProvider).valueOrNull?.player;
    final academyId = sessionPlayer?['academy_id'] as String?;
    if (academyId == null || academyId.isEmpty) return const SizedBox.shrink();

    final academyAsync = ref.watch(academyByIdProvider(academyId));
    final academy = academyAsync.valueOrNull;
    if (academy == null) return const SizedBox.shrink();

    final links = <(IconData, String)>[
      if ((academy.websiteUrl ?? '').isNotEmpty) (Icons.language, academy.websiteUrl!),
      if ((academy.facebookUrl ?? '').isNotEmpty) (Icons.facebook, academy.facebookUrl!),
      if ((academy.tiktokUrl ?? '').isNotEmpty) (Icons.music_note, academy.tiktokUrl!),
      if ((academy.instagramUrl ?? '').isNotEmpty) (Icons.camera_alt_outlined, academy.instagramUrl!),
    ];
    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final link in links)
                IconButton(
                  onPressed: () => _openSocialLink(context, link.$2),
                  icon: Icon(link.$1, color: AppColors.secondary),
                ),
            ],
          ),
        ),
        Gap(16.h),
      ],
    );
  }

  Future<void> _openSocialLink(BuildContext context, String url) async {
    var target = url.trim();
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      target = 'https://$target';
    }
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        ok = false;
      }
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط')),
      );
    }
  }

  // ── تحية حسب الوقت ──
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير';
    if (h < 18) return 'مساء الخير';
    return 'مساء الخير';
  }

  Widget _header(BuildContext context, WidgetRef ref, Map<String, dynamic>? p) {
    final name = p?['fullName'] as String? ?? '';
    final code = p?['playerCode'] as String? ?? '';
    final imageUrl = p?['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryLight],
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => showPlayerPhotoSheet(context, ref,
                hasImage: hasImage, imageUrl: imageUrl),
            customBorder: const CircleBorder(),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: AppColors.white,
                  backgroundImage:
                      hasImage ? CachedNetworkImageProvider(imageUrl) : null,
                  child: hasImage
                      ? null
                      : Icon(Icons.person, color: AppColors.secondary, size: 30.sp),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit,
                        size: 11.sp, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_greeting()} 👋',
                    style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 12.sp)),
                Gap(2.h),
                Text(name,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800)),
                Gap(4.h),
                Text(code,
                    style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8), fontSize: 13.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── بانر تنبيه الاشتراك — يظهر فقط عند غياب اشتراك/انتهائه/قربه ──
  // [renewal] آخر طلب تجديد أرسله اللاعب (من الـ dashboard) أو null.
  Widget? _subscriptionAlert(
    BuildContext context,
    Map<String, dynamic>? sub,
    Map<String, dynamic>? renewal,
  ) {
    final active = sub?['isActive'] == true;
    final days = (sub?['daysRemaining'] as num?)?.toInt() ?? 0;
    // اشتراك نشط وبعيد عن الانتهاء: لا بانر.
    if (sub != null && active && days > 7) return null;

    // في كل حالة تحتاج تجديداً (لا اشتراك / منتهٍ / قارب على الانتهاء) يكون
    // الإجراء "تجديد" — إرسال إيصال الدفع للمراجعة. كان "تواصل" يظهر بدلاً منه
    // للاعب بلا اشتراك مسجّل أو قارب اشتراكه على الانتهاء.
    final renewalStatus = renewal?['status'] as String?;
    if (renewalStatus == 'pending') {
      return _alertBanner(
        context,
        color: AppColors.warning,
        bg: AppColors.warningLight,
        icon: Icons.hourglass_top_outlined,
        title: 'طلب التجديد قيد المراجعة',
        message: 'تم استلام إيصالك، وسيتم تجديد اشتراكك بعد مراجعة الإدارة.',
        actionLabel: null,
      );
    }
    void openRenewal() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlayerRenewalRequestScreen()),
        );
    final reason = (renewal?['rejectionReason'] as String?)?.trim() ?? '';

    if (renewalStatus == 'rejected') {
      return _alertBanner(
        context,
        color: AppColors.error,
        bg: AppColors.errorLight,
        icon: Icons.error_outline,
        title: 'تم رفض طلب التجديد',
        message: reason.isNotEmpty ? reason : 'يمكنك إرسال طلب تجديد جديد.',
        actionLabel: 'تجديد',
        onAction: openRenewal,
        showContact: true,
      );
    }
    if (sub == null) {
      return _alertBanner(
        context,
        color: AppColors.warning,
        bg: AppColors.warningLight,
        icon: Icons.info_outline,
        title: 'لا يوجد اشتراك مسجّل',
        message: 'أرسل إيصال الدفع لتفعيل اشتراكك.',
        actionLabel: 'تجديد',
        onAction: openRenewal,
        showContact: true,
      );
    }
    if (!active) {
      return _alertBanner(
        context,
        color: AppColors.error,
        bg: AppColors.errorLight,
        icon: Icons.error_outline,
        title: 'اشتراكك منتهٍ',
        message: 'جدّد اشتراكك لمواصلة التدريبات.',
        actionLabel: 'تجديد',
        onAction: openRenewal,
        showContact: true,
      );
    }
    return _alertBanner(
      context,
      color: AppColors.warning,
      bg: AppColors.warningLight,
      icon: Icons.access_time,
      title: 'اشتراكك يقارب الانتهاء',
      message: 'باقٍ $days ${days == 1 ? 'يوم' : 'أيام'} على انتهاء الاشتراك.',
      actionLabel: 'تجديد',
      onAction: openRenewal,
      showContact: true,
    );
  }

  Widget _alertBanner(
    BuildContext context, {
    required Color color,
    required Color bg,
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    // رابط "تواصل" ثانوي (محادثة الأكاديمية) أسفل الرسالة.
    bool showContact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26.sp),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800)),
                Gap(2.h),
                Text(message,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey700)),
                if (showContact)
                  InkWell(
                    onTap: () => context.push(AppRoutes.playerChat),
                    child: Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text('تواصل مع الأكاديمية',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null) ...[
            Gap(8.w),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  // ── صف الإحصائيات السريعة ──
  Widget _statsRow(
    Map<String, dynamic>? sub,
    Map<String, dynamic>? att,
    Map<String, dynamic>? ev,
  ) {
    final active = sub?['isActive'] == true;
    final days = (sub?['daysRemaining'] as num?)?.toInt();
    final count = (att?['presentCount'] as num?)?.toInt() ?? 0;
    final avg = ev?['average'];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _statTile(
              icon: Icons.event_available_outlined,
              value: days?.toString() ?? '—',
              label: 'يوم متبقٍ',
              color: sub == null
                  ? AppColors.grey500
                  : (!active || (days ?? 0) <= 7
                      ? AppColors.error
                      : AppColors.success),
            ),
          ),
          Gap(10.w),
          Expanded(
            child: _statTile(
              icon: Icons.how_to_reg_outlined,
              value: '$count',
              label: 'مرة حضور',
              color: AppColors.primary,
            ),
          ),
          Gap(10.w),
          Expanded(
            child: _statTile(
              icon: Icons.star_outline,
              value: avg != null ? '$avg' : '—',
              label: 'متوسط التقييم',
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.r, horizontal: 8.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22.sp),
          Gap(8.h),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 20.sp, fontWeight: FontWeight.w900, color: color)),
          Gap(2.h),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.sp, color: AppColors.grey600)),
        ],
      ),
    );
  }

  // ── الإجراءات السريعة — المتجر والألبوم وطقم الفريق والفيديوهات ──
  // صفّان من بطاقتين بدل صفّ واحد من أربعة: البطاقات تبقى مقروءة على شاشة
  // الهاتف بدل أن تُضغط في أعمدة ضيّقة.
  Widget _quickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4.r, bottom: 10.h),
          child: Text('الإجراءات السريعة',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _actionTile(
                  icon: Icons.storefront_outlined,
                  title: 'متجر الأكاديمية',
                  subtitle: 'تصفّح المنتجات واطلب عبر واتساب',
                  colors: const [AppColors.primary, AppColors.primaryLight],
                  onTap: () => context.push(AppRoutes.playerStore),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: _actionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'ألبوم الأكاديمية',
                  subtitle: 'شاهد صور الأكاديمية وشاركها',
                  colors: const [AppColors.secondary, AppColors.secondaryLight],
                  onTap: () => context.push(AppRoutes.playerAlbum),
                ),
              ),
            ],
          ),
        ),
        Gap(12.h),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _actionTile(
                  icon: Icons.checkroom_outlined,
                  title: 'طقم الفريق',
                  subtitle: 'احجز طقمك بمقاسك',
                  colors: const [AppColors.primaryDark, AppColors.primary],
                  onTap: () => context.push(AppRoutes.playerTeamKit),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: _actionTile(
                  icon: Icons.video_library_outlined,
                  title: 'فيديوهاتي',
                  subtitle: 'شاهد فيديوهاتك وعلّق وسجّل إعجابك',
                  colors: const [AppColors.secondaryDark, AppColors.secondary],
                  onTap: () => context.push(AppRoutes.playerMyVideos),
                ),
              ),
            ],
          ),
        ),
        Gap(12.h),
        _actionTile(
          icon: Icons.emoji_events_outlined,
          title: 'البطولات',
          subtitle: 'جدول مبارياتك والترتيب وشجرة الكأس',
          colors: const [AppColors.warning, Color(0xFFFBBF24)],
          onTap: () => context.push(AppRoutes.playerTournaments),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: AppColors.white, size: 26.sp),
            ),
            Gap(12.h),
            Text(title,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800)),
            Gap(4.h),
            Text(subtitle,
                style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 11.5.sp,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22.sp),
              Gap(8.w),
              Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
            ],
          ),
          Gap(12.h),
          child,
        ],
      ),
    );
  }

  Widget _emptyHint(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.grey400),
        Gap(8.w),
        Text(text, style: TextStyle(fontSize: 13.sp, color: AppColors.grey500)),
      ],
    );
  }

  // ── اليوم بالعربية لمطابقة أيام الجدول ──
  String _arabicToday() {
    const names = {
      DateTime.saturday: 'السبت',
      DateTime.sunday: 'الأحد',
      DateTime.monday: 'الإثنين',
      DateTime.tuesday: 'الثلاثاء',
      DateTime.wednesday: 'الأربعاء',
      DateTime.thursday: 'الخميس',
      DateTime.friday: 'الجمعة',
    };
    return names[DateTime.now().weekday] ?? '';
  }

  Widget _scheduleCard(Map<String, dynamic>? schedule) {
    final days = (schedule?['attendanceDays'] as List<dynamic>?)?.cast<String>() ?? [];
    final today = _arabicToday();
    return _card(
      title: 'جدول التدريب',
      icon: Icons.calendar_month_outlined,
      child: days.isEmpty
          ? _emptyHint(Icons.event_busy_outlined, 'لم يتم تحديد أيام تدريب')
          : Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: days.map((d) {
                final isToday = d == today;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 7.r),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isToday) ...[
                        Icon(Icons.today, size: 14.sp, color: AppColors.white),
                        Gap(4.w),
                      ],
                      Text(
                        isToday ? '$d • اليوم' : d,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isToday ? AppColors.white : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _attendanceCard(Map<String, dynamic>? att) {
    final count = (att?['presentCount'] as num?)?.toInt() ?? 0;
    final absent = (att?['absentCount'] as num?)?.toInt() ?? 0;
    final recent = (att?['recent'] as List<dynamic>?) ?? const [];
    return _card(
      title: 'الحضور',
      icon: Icons.how_to_reg_outlined,
      child: recent.isEmpty
          ? _emptyHint(Icons.event_busy_outlined, 'لا يوجد حضور مسجّل بعد')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // على أساس الاشتراك الحالي (نفس حساب الإدارة).
                Text('في الاشتراك الحالي: حضور $count — غياب $absent',
                    style: TextStyle(fontSize: 14.sp)),
                Gap(4.h),
                Text('آخر حضور: ${(recent.first as Map)['date'] ?? '—'}',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w600)),
                Gap(12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: recent.take(6).map((r) {
                    final m = r as Map;
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 6.r),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 13.sp, color: AppColors.success),
                          Gap(5.w),
                          Text('${m['date'] ?? ''}',
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.grey700)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  Widget _evaluationCard(List<dynamic> evals, Map<String, dynamic>? latest) {
    if (evals.isEmpty) {
      return _card(
        title: 'التقييمات',
        icon: Icons.star_outline,
        child: _emptyHint(Icons.star_border, 'لا يوجد تقييم بعد'),
      );
    }
    // ترتيب زمني تصاعدي لعرض التطوّر (الخادم يرجّعها تنازلياً).
    final points = evals.reversed
        .map((e) => ((e as Map)['average'] as num?)?.toDouble() ?? 0)
        .toList();
    final show = points.length > 6 ? points.sublist(points.length - 6) : points;
    final avg = latest?['average'];
    return _card(
      title: 'التقييمات',
      icon: Icons.star_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${avg ?? '—'}',
                  style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary)),
              Gap(4.w),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text('/ 10 — آخر تقييم',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
              ),
            ],
          ),
          Gap(14.h),
          SizedBox(
            height: 70.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: show.map((v) {
                final ratio = (v / 10).clamp(0.05, 1.0);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(v.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 9.sp,
                                color: AppColors.grey600,
                                fontWeight: FontWeight.w600)),
                        Gap(3.h),
                        Container(
                          height: 46.h * ratio,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4.r)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
