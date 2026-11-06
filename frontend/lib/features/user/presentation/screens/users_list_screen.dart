import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/user/domain/entities/user_management_entity.dart';
import 'package:hurghada_winners/features/user/presentation/providers/user_provider.dart';
import 'package:hurghada_winners/features/user/presentation/screens/add_user_screen.dart';
import 'package:hurghada_winners/features/user/presentation/screens/edit_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  final String academyId;

  const UsersListScreen({super.key, required this.academyId});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedAcademyIdProvider.notifier).state = widget.academyId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مستخدمو الأكاديمية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.read(usersProvider.notifier).refresh(),
        ),
        data: (users) => users.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () => ref.read(usersProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => Gap(12.h),
                  itemBuilder: (context, index) {
                    return _UserCard(
                      user: users[index],
                      isSuperAdmin: isSuperAdmin,
                      onEdit: () => _openEdit(context, users[index]),
                      onActivate: () => _toggleActive(context, users[index]),
                      onDelete: () => _confirmDelete(context, users[index]),
                      onResetPassword: () =>
                          _resetPassword(context, users[index]),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddUserScreen(academyId: widget.academyId),
                ),
              ),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('إضافة مستخدم'),
            )
          : null,
    );
  }

  Future<void> _resetPassword(
      BuildContext context, UserManagementEntity user) async {
    final formKey = GlobalKey<FormState>();
    final passController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;

    final newPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تعيين كلمة مرور جديدة للمستخدم "${user.name}"',
                  style: const TextStyle(fontSize: 13, color: AppColors.grey600),
                ),
                Gap(16.h),
                TextFormField(
                  controller: passController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setLocal(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                    if (v.length < 8) {
                      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                Gap(12.h),
                TextFormField(
                  controller: confirmController,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                  ),
                  validator: (v) {
                    if (v != passController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(passController.text);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (newPassword == null) return;
    if (!context.mounted) return;

    final error = await ref
        .read(usersProvider.notifier)
        .resetPassword(user.id, newPassword);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم تغيير كلمة المرور بنجاح'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openEdit(BuildContext context, UserManagementEntity user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditUserScreen(user: user),
      ),
    );
  }

  Future<void> _toggleActive(
      BuildContext context, UserManagementEntity user) async {
    final notifier = ref.read(usersProvider.notifier);
    final String? error;
    if (user.isActive) {
      error = await notifier.deactivateUser(user.id);
    } else {
      error = await notifier.activateUser(user.id);
    }
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
      final msg =
          user.isActive ? 'تم إيقاف تفعيل المستخدم' : 'تم تفعيل المستخدم';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, UserManagementEntity user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text('هل تريد حذف "${user.name}"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final error = await ref.read(usersProvider.notifier).deleteUser(user.id);
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
          content: Text('تم حذف المستخدم بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// User card
// ---------------------------------------------------------------------------

class _UserCard extends StatelessWidget {
  final UserManagementEntity user;
  final bool isSuperAdmin;
  final VoidCallback onEdit;
  final VoidCallback onActivate;
  final VoidCallback onDelete;
  final VoidCallback onResetPassword;

  const _UserCard({
    required this.user,
    required this.isSuperAdmin,
    required this.onEdit,
    required this.onActivate,
    required this.onDelete,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onLongPress: isSuperAdmin ? () => _showOptions(context) : null,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              Gap(12.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(2.h),
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(6.h),
                    Row(
                      children: [
                        _RoleBadge(role: user.role),
                        Gap(8.w),
                        _ActiveChip(isActive: user.isActive),
                      ],
                    ),
                  ],
                ),
              ),
              // Options menu for super admin
              if (isSuperAdmin)
                IconButton(
                  icon: Icon(Icons.more_vert,
                      color: AppColors.grey400, size: 20.sp),
                  onPressed: () => _showOptions(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gap(8.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Gap(16.h),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('تعديل المستخدم'),
              onTap: () {
                Navigator.of(ctx).pop();
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(
                user.isActive
                    ? Icons.block_outlined
                    : Icons.check_circle_outline,
                color: user.isActive ? AppColors.warning : AppColors.success,
              ),
              title: Text(
                user.isActive ? 'إيقاف التفعيل' : 'تفعيل المستخدم',
                style: TextStyle(
                  color:
                      user.isActive ? AppColors.warning : AppColors.success,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                onActivate();
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined,
                  color: AppColors.primary),
              title: const Text('تغيير كلمة المرور'),
              onTap: () {
                Navigator.of(ctx).pop();
                onResetPassword();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'حذف المستخدم',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                onDelete();
              },
            ),
            Gap(8.h),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        role == 'academy_admin'
            ? 'مدير أكاديمية'
            : role == 'admin'
                ? 'مشرف'
                : 'مشرف عام',
        style: TextStyle(
          fontSize: 11.sp,
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final bool isActive;
  const _ActiveChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 12.sp,
            color: isActive ? AppColors.success : AppColors.error,
          ),
          Gap(4.w),
          Text(
            isActive ? 'مفعّل' : 'موقوف',
            style: TextStyle(
              fontSize: 11.sp,
              color: isActive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / Error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80.sp, color: AppColors.grey300),
          Gap(16.h),
          Text(
            'لا يوجد مستخدمون بعد',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.grey500),
          ),
          Gap(8.h),
          Text(
            'أضف أول مستخدم للأكاديمية',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            Gap(16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gap(16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
