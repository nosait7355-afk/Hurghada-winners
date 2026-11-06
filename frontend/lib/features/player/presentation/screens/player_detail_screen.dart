import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/core/widgets/full_screen_image_viewer.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/evaluation/presentation/providers/evaluation_provider.dart';
import 'package:hurghada_winners/features/evaluation/presentation/screens/add_evaluation_screen.dart';
import 'package:hurghada_winners/features/evaluation/presentation/screens/evaluation_history_screen.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/presentation/providers/player_provider.dart';
import 'package:hurghada_winners/features/player/presentation/screens/edit_player_screen.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_card_screen.dart';
import 'package:hurghada_winners/features/player/presentation/widgets/player_account_section.dart';
import 'package:hurghada_winners/features/player/presentation/widgets/player_share_sheet.dart';
import 'package:hurghada_winners/features/player_videos/presentation/screens/player_videos_screen.dart';
import 'package:hurghada_winners/features/subscription/domain/entities/subscription_entity.dart';
import 'package:hurghada_winners/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/add_subscription_screen.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/player_subscription_history_screen.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/renew_subscription_screen.dart';
import 'package:hurghada_winners/features/whatsapp/presentation/widgets/communication_section.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;
  final String academyId;

  const PlayerDetailScreen({
    super.key,
    required this.playerId,
    required this.academyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // النسخة المحمّلة في قائمة اللاعبين (إن وُجدت) تُعرض فوراً وتبقى متزامنة
    // مع التعديل/الحذف من القائمة. غير ذلك نجلب اللاعب بمعرّفه من الخادم —
    // الصفحة تُفتح من شاشات كثيرة لا يكون اللاعب فيها ضمن الصفحة المحمّلة.
    final listed = ref.watch(playersProvider).valueOrNull?.players;
    PlayerEntity? cached;
    for (final p in listed ?? const <PlayerEntity>[]) {
      if (p.id == playerId) {
        cached = p;
        break;
      }
    }
    if (cached != null) {
      return _PlayerDetailContent(player: cached, academyId: cached.academyId);
    }

    return ref.watch(playerByIdProvider(playerId)).when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.playerDetails)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.playerDetails)),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined,
                    size: 80.sp, color: AppColors.grey300),
                Gap(16.h),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.grey600),
                ),
                Gap(16.h),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(playerByIdProvider(playerId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      // أكاديمية اللاعب نفسه هي المرجع — لا المُمرَّرة (قد تكون 'all' في وضع كل الفروع).
      data: (player) =>
          _PlayerDetailContent(player: player, academyId: player.academyId),
    );
  }
}

class _PlayerDetailContent extends ConsumerWidget {
  final PlayerEntity player;
  final String academyId;

  const _PlayerDetailContent({
    required this.player,
    required this.academyId,
  });

  Widget _buildSubscriptionActionsCard(
      BuildContext context, PlayerEntity player, bool canEdit) {
    if (!canEdit) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 0.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.subscriptions,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            Gap(12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlayerSubscriptionHistoryScreen(
                          playerId: player.id,
                          academyId: academyId,
                          playerName: player.fullName,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.history),
                    label: const Text('سجل الاشتراكات'),
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddSubscriptionScreen(
                          playerId: player.id,
                          academyId: academyId,
                          playerName: player.fullName,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add_card),
                    label: const Text('اشتراك جديد'),
                  ),
                ),
              ],
            ),
            Gap(8.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RenewSubscriptionScreen(
                    playerId: player.id,
                    academyId: academyId,
                    playerName: player.fullName,
                  ),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('تجديد الاشتراك'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('حذف اللاعب'),
        content: const Text(AppStrings.deletePlayerConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final error =
        await ref.read(playersProvider.notifier).deletePlayer(player.id);

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.playerDeleted),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;
    final isAcademyLevelSame =
        !isSuperAdmin && authState?.user?.academyId == academyId;
    final canEdit = isSuperAdmin || isAcademyLevelSame;

    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.playerDetails),
        centerTitle: true,
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'مشاركة البروفايل',
              onPressed: () => showPlayerShareSheet(
                context,
                playerId: player.id,
                playerName: player.fullName,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.edit,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditPlayerScreen(
                      player: player,
                      academyId: academyId,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: AppStrings.delete,
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: AppColors.primaryContainer,
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Column(
                children: [
                  // Player photo — الضغط يفتحها ملء الشاشة
                  GestureDetector(
                    onTap: player.imageUrl != null && player.imageUrl!.isNotEmpty
                        ? () => showFullScreenImage(context, player.imageUrl!)
                        : null,
                    child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: player.imageUrl != null &&
                              player.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: player.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 64.sp,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 64.sp,
                            ),
                    ),
                  ),
                  ),
                  Gap(16.h),
                  // Player code chip
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      player.playerCode,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Gap(10.h),
                  Text(
                    player.fullName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Gap(8.h),
                  _PlayerStatusBadge(playerId: player.id),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player info card
                  Text(
                    AppStrings.playerInfo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  Gap(12.h),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        label: AppStrings.birthDate,
                        value: dateFormat.format(player.birthDate),
                      ),
                      _RowDivider(),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: AppStrings.age,
                        value: '${player.age} ${AppStrings.yearsOld}',
                      ),
                      if (player.playerPhone != null &&
                          player.playerPhone!.isNotEmpty) ...[
                        _RowDivider(),
                        _InfoRow(
                          icon: Icons.phone_android_outlined,
                          label: AppStrings.playerPhone,
                          value: player.playerPhone!,
                        ),
                      ],
                      if (isSuperAdmin) ...[
                        _RowDivider(),
                        _InfoRow(
                          icon: Icons.business_outlined,
                          label: 'معرّف الأكاديمية',
                          value: player.academyId,
                        ),
                      ],
                    ],
                  ),

                  Gap(24.h),

                  // Parent info card
                  Text(
                    AppStrings.parentInfo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  Gap(12.h),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: AppStrings.parentName,
                        value: player.parentName,
                      ),
                      _RowDivider(),
                      _InfoRow(
                        icon: Icons.family_restroom_outlined,
                        label: AppStrings.parentRelationship,
                        value: player.parentRelationship,
                      ),
                      if (player.parentJob != null &&
                          player.parentJob!.isNotEmpty) ...[
                        _RowDivider(),
                        _InfoRow(
                          icon: Icons.work_outline,
                          label: AppStrings.parentJob,
                          value: player.parentJob!,
                        ),
                      ],
                      _RowDivider(),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: AppStrings.parentPhone,
                        value: player.parentPhone,
                      ),
                    ],
                  ),

                  // Notes
                  if (player.notes != null && player.notes!.isNotEmpty) ...[
                    Gap(24.h),
                    Text(
                      AppStrings.notes,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                    Gap(12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        player.notes!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey700,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  Gap(16.h),
                  // Player Card (QR) button — متاح للجميع لعرض/طباعة البطاقة
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerCardScreen(player: player),
                        ),
                      ),
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('بطاقة اللاعب'),
                    ),
                  ),

                  Gap(10.h),
                  // فيديوهات البروفايل — تضيفها الإدارة كروابط، ويشاهدها
                  // اللاعب في حسابه ويتفاعل معها بالإعجاب والتعليق.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerVideosScreen(
                            playerId: player.id,
                            playerName: player.fullName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.video_library_outlined),
                      label: const Text('فيديوهات اللاعب'),
                    ),
                  ),

                  Gap(16.h),
                  // Player Account Card (Player Portal)
                  PlayerAccountSection(
                    playerId: player.id,
                    playerName: player.fullName,
                    canEdit: canEdit,
                  ),

                  Gap(16.h),
                  // Subscription Actions Card
                  _buildSubscriptionActionsCard(context, player, canEdit),

                  Gap(8.h),
                  _LatestEvaluationCard(
                    playerId: player.id,
                    academyId: academyId,
                    playerName: player.fullName,
                    canEdit: canEdit,
                  ),
                  Gap(16.h),

                  // Communication section (WhatsApp)
                  _CommunicationWidget(player: player),
                  Gap(80.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info card / row helpers
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.grey500),
                ),
                Gap(2.h),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 68.w,
      endIndent: 16.w,
      color: AppColors.grey100,
    );
  }
}

// ---------------------------------------------------------------------------
// Latest Evaluation Card
// ---------------------------------------------------------------------------

class _LatestEvaluationCard extends ConsumerWidget {
  final String playerId;
  final String academyId;
  final String playerName;
  final bool canEdit;

  const _LatestEvaluationCard({
    required this.playerId,
    required this.academyId,
    required this.playerName,
    required this.canEdit,
  });

  Widget _scoreRow(BuildContext context, String label, double value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ),
          Text(
            '${value.toInt()}/10',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final latestAsync = ref.watch(latestEvaluationProvider(playerId));

    return latestAsync.when(
      loading: () => const SizedBox.shrink(),
      // عند خطأ: نعرض بطاقة "لا توجد تقييمات" مع زر الإضافة
      error: (_, __) => Card(
        margin: EdgeInsets.symmetric(horizontal: 0.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.latestEvaluation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
              Gap(8.h),
              Text(
                AppStrings.noEvaluations,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500,
                ),
              ),
              if (canEdit) ...[
                Gap(8.h),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEvaluationScreen(
                        playerId: playerId,
                        academyId: academyId,
                        playerName: playerName,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add_chart),
                  label: const Text(AppStrings.addEvaluation),
                ),
              ],
            ],
          ),
        ),
      ),
      data: (evaluation) {
        if (evaluation == null) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 0.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.latestEvaluation,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  Gap(8.h),
                  Text(
                    AppStrings.noEvaluations,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                  if (canEdit) ...[
                    Gap(8.h),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEvaluationScreen(
                            playerId: playerId,
                            academyId: academyId,
                            playerName: playerName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add_chart),
                      label: const Text(AppStrings.addEvaluation),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        Color gradeColor;
        Color gradeBgColor;
        if (evaluation.average >= 8) {
          gradeColor = AppColors.success;
          gradeBgColor = AppColors.successLight;
        } else if (evaluation.average >= 6) {
          gradeColor = AppColors.warning;
          gradeBgColor = AppColors.warningLight;
        } else {
          gradeColor = AppColors.error;
          gradeBgColor = AppColors.errorLight;
        }

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 0.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppStrings.latestEvaluation,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: gradeBgColor,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        evaluation.gradeLabel,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: gradeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(8.h),
                Center(
                  child: Text(
                    evaluation.average.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    AppStrings.averageScore,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ),
                Gap(8.h),
                const Divider(height: 1, color: AppColors.grey100),
                Gap(8.h),
                _scoreRow(context, AppStrings.fitnessScore, evaluation.fitness),
                _scoreRow(context, AppStrings.basicSkillsScore,
                    evaluation.basicSkills),
                _scoreRow(context, AppStrings.attackScore, evaluation.attack),
                _scoreRow(
                    context, AppStrings.defenseScore, evaluation.defense),
                _scoreRow(
                    context, AppStrings.commitmentScore, evaluation.commitment),
                Gap(8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EvaluationHistoryScreen(
                            playerId: playerId,
                            academyId: academyId,
                            playerName: playerName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.history),
                      label: const Text('عرض كل التقييمات'),
                    ),
                    if (canEdit)
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEvaluationScreen(
                              playerId: playerId,
                              academyId: academyId,
                              playerName: playerName,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add_chart),
                        label: const Text(AppStrings.addEvaluation),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Communication Widget (WhatsApp)
// ---------------------------------------------------------------------------

class _CommunicationWidget extends ConsumerWidget {
  final PlayerEntity player;
  const _CommunicationWidget({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(playerSubscriptionsProvider(player.id));
    final latestEvalAsync = ref.watch(latestEvaluationProvider(player.id));

    SubscriptionEntity? latestSub;
    subsAsync.whenData((subs) {
      if (subs.isNotEmpty) {
        final sorted = [...subs]
          ..sort((a, b) => b.endDate.compareTo(a.endDate));
        latestSub = sorted.first;
      }
    });

    final academyName =
        ref.watch(academyByIdProvider(player.academyId)).valueOrNull?.name ??
            'الأكاديمية';

    return CommunicationSection(
      player: player,
      academyName: academyName,
      latestSubscription: latestSub,
      latestEvaluation: latestEvalAsync.valueOrNull,
    );
  }
}

// ---------------------------------------------------------------------------
// Player Status Badge
// ---------------------------------------------------------------------------

class _PlayerStatusBadge extends ConsumerWidget {
  final String playerId;
  const _PlayerStatusBadge({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(playerStatusProvider(playerId));
    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) => _StatusChip(status: status),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case 'نشط':
        bg = AppColors.successLight;
        fg = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case 'منتهي':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        icon = Icons.cancel_outlined;
        break;
      default: // جديد
        bg = AppColors.primaryContainer;
        fg = AppColors.primaryDark;
        icon = Icons.fiber_new_outlined;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: fg),
          Gap(4.w),
          Text(
            status,
            style: TextStyle(
              fontSize: 12.sp,
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
