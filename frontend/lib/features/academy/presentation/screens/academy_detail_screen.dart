import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/academy/domain/entities/academy_entity.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/academy/presentation/screens/edit_academy_screen.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AcademyDetailScreen extends ConsumerWidget {
  final String academyId;

  const AcademyDetailScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academiesAsync = ref.watch(academiesProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;

    return academiesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.academy)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.academy)),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
                Gap(16.h),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Gap(16.h),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(academiesProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (academies) {
        AcademyEntity? academy;
        try {
          academy = academies.firstWhere((a) => a.id == academyId);
        } catch (_) {
          academy = null;
        }

        if (academy == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.academy)),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_outlined,
                        size: 64.sp, color: AppColors.grey400),
                    Gap(16.h),
                    Text(
                      'الفرع غير موجود',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.grey500),
                    ),
                    Gap(16.h),
                    ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text(AppStrings.back),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _AcademyDetailContent(
          academy: academy,
          isSuperAdmin: isSuperAdmin,
        );
      },
    );
  }
}

class _AcademyDetailContent extends ConsumerWidget {
  final AcademyEntity academy;
  final bool isSuperAdmin;

  const _AcademyDetailContent({
    required this.academy,
    required this.isSuperAdmin,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('حذف الفرع'),
        content: Text(
          'هل أنت متأكد من حذف فرع "${academy.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
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
        await ref.read(academiesProvider.notifier).deleteAcademy(academy.id);

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
          content: Text('تم حذف الفرع بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    // الحسابات الإدارية المحدودة لا ترى مدخل التقارير.
    final canViewReports =
        ref.watch(authStateProvider).valueOrNull?.user?.canViewReports != false;

    return Scaffold(
      appBar: AppBar(
        title: Text(academy.name),
        centerTitle: true,
        actions: [
          if (isSuperAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.edit,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditAcademyScreen(academy: academy),
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
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditAcademyScreen(academy: academy),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text(AppStrings.edit),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero header
            Container(
              color: AppColors.primaryContainer,
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: academy.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: Image.network(
                              academy.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _DefaultLogoIcon(),
                            ),
                          )
                        : _DefaultLogoIcon(),
                  ),
                  Gap(16.h),
                  Text(
                    academy.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (academy.playerCount != null) ...[
                    Gap(8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${academy.playerCount} لاعب',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Details section
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معلومات الفرع',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  Gap(16.h),
                  _DetailCard(
                    children: [
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'رقم الهاتف',
                        value: academy.phone,
                      ),
                      _RowDivider(),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'العنوان',
                        value: academy.address,
                      ),
                      _RowDivider(),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'تاريخ الإنشاء',
                        value: dateFormat.format(academy.createdAt),
                      ),
                      if (academy.updatedAt != null) ...[
                        _RowDivider(),
                        _DetailRow(
                          icon: Icons.update_outlined,
                          label: 'آخر تحديث',
                          value: dateFormat.format(academy.updatedAt!),
                        ),
                      ],
                    ],
                  ),

                  Gap(24.h),
                  Text(
                    'الإدارة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  Gap(16.h),
                  _DetailCard(
                    children: [
                      InkWell(
                        onTap: () => context.push(
                          AppRoutes.playersList.replaceFirst(
                              ':id', academy.id),
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          child: Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.sports_tennis_outlined,
                                  color: AppColors.primary,
                                  size: 20.sp,
                                ),
                              ),
                              Gap(12.w),
                              Expanded(
                                child: Text(
                                  AppStrings.players,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey800,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_left,
                                color: AppColors.grey400,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _RowDivider(),
                      InkWell(
                        onTap: () => context.push(
                          AppRoutes.groupsList.replaceFirst(
                              ':id', academy.id),
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          child: Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.groups_outlined,
                                  color: AppColors.primary,
                                  size: 20.sp,
                                ),
                              ),
                              Gap(12.w),
                              Expanded(
                                child: Text(
                                  'المجموعات',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey800,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_left,
                                color: AppColors.grey400,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _RowDivider(),
                      if (isSuperAdmin)
                        InkWell(
                          onTap: () => context.push(
                            AppRoutes.academyUsers.replaceFirst(
                                ':id', academy.id),
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.manage_accounts_outlined,
                                    color: AppColors.primary,
                                    size: 20.sp,
                                  ),
                                ),
                                Gap(12.w),
                                Expanded(
                                  child: Text(
                                    AppStrings.academyUsers,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.grey800,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_left,
                                  color: AppColors.grey400,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (canViewReports) ...[
                      _RowDivider(),
                      InkWell(
                        onTap: () => context.push(AppRoutes.reports),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          child: Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.bar_chart_outlined,
                                  color: AppColors.primary,
                                  size: 20.sp,
                                ),
                              ),
                              Gap(12.w),
                              Expanded(
                                child: Text(
                                  AppStrings.reports,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey800,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_left,
                                color: AppColors.grey400,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ],
                    ],
                  ),

                  if (isSuperAdmin) ...[
                    Gap(24.h),
                    Text(
                      'إجراءات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                    Gap(16.h),
                    _DetailCard(
                      children: [
                        InkWell(
                          onTap: () => _confirmDelete(context, ref),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 20.sp,
                                  ),
                                ),
                                Gap(12.w),
                                Expanded(
                                  child: Text(
                                    'حذف الفرع',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_left,
                                  color: AppColors.error,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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

class _DefaultLogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.sports_tennis,
      color: AppColors.primary,
      size: 48.sp,
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

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
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
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
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey500,
                  ),
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
