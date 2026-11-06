import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/layout/desktop_scaffold.dart';
import 'package:hurghada_winners/core/layout/responsive.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/core/utils/privacy_launcher.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// إعدادات الحساب — تظهر للمستخدم الحالي فقط:
/// تعديل الاسم + تغيير كلمة المرور الخاصة به.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _nameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _savingName = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull?.user;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveName() async {
    if (!_nameFormKey.currentState!.validate()) return;
    setState(() => _savingName = true);
    final error = await ref
        .read(authStateProvider.notifier)
        .updateName(_nameController.text.trim());
    if (!mounted) return;
    setState(() => _savingName = false);
    _snack(error ?? 'تم تحديث الاسم بنجاح', error: error != null);
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    final error = await ref.read(authStateProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
    if (!mounted) return;
    setState(() => _savingPassword = false);
    if (error == null) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
    _snack(error ?? 'تم تغيير كلمة المرور بنجاح', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final tier =
        kIsWeb ? screenTierOf(MediaQuery.sizeOf(context).width) : ScreenTier.mobile;

    if (tier != ScreenTier.mobile) {
      return DesktopScaffold(
        location: AppRoutes.accountSettings,
        tier: tier,
        title: 'إعدادات الحساب',
        // Settings forms read better at a fixed readable width than
        // stretched edge-to-edge — this is a per-screen content choice, not
        // an app-wide letterbox/clamp.
        content: Center(
          child: SizedBox(width: 560, child: _buildBody(context)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعدادات الحساب'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull?.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            // Current account summary
            Center(
              child: CircleAvatar(
                radius: 40.r,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  (user?.name.isNotEmpty ?? false)
                      ? user!.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            Gap(8.h),
            Center(
              child: Text(
                user?.email ?? '',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.grey500),
              ),
            ),
            Gap(24.h),

            // ── Name section ──────────────────────────────────────────────
            _SectionCard(
              title: 'الاسم',
              child: Form(
                key: _nameFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'الاسم مطلوب';
                        }
                        if (v.trim().length < 2) {
                          return 'الاسم يجب أن يكون حرفين على الأقل';
                        }
                        return null;
                      },
                    ),
                    Gap(14.h),
                    ElevatedButton(
                      onPressed: _savingName ? null : _saveName,
                      child: _savingName
                          ? SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('حفظ الاسم'),
                    ),
                  ],
                ),
              ),
            ),
            Gap(20.h),

            // ── Password section ─────────────────────────────────────────
            _SectionCard(
              title: 'تغيير كلمة المرور',
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور الحالية',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'كلمة المرور الحالية مطلوبة'
                          : null,
                    ),
                    Gap(14.h),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور الجديدة',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'كلمة المرور الجديدة مطلوبة';
                        }
                        if (v.length < 8) {
                          return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    Gap(14.h),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureNew,
                      decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور الجديدة',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) {
                        if (v != _newPasswordController.text) {
                          return 'كلمتا المرور غير متطابقتين';
                        }
                        return null;
                      },
                    ),
                    Gap(14.h),
                    ElevatedButton(
                      onPressed: _savingPassword ? null : _savePassword,
                      child: _savingPassword
                          ? SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('تغيير كلمة المرور'),
                    ),
                  ],
                ),
              ),
            ),
            Gap(20.h),

            // ── Privacy policy ───────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r)),
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined,
                    color: AppColors.primary),
                title: const Text('سياسة الخصوصية'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openPrivacyPolicy(context),
              ),
            ),
            Gap(12.h),

            // ── الدعم الفني (واتساب) ─────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r)),
              child: ListTile(
                leading: const Icon(Icons.support_agent,
                    color: Color(0xFF25D366)),
                title: const Text('الدعم الفني'),
                subtitle: const Text('مراسلة على واتساب'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => WhatsAppUtils.openSupport(context),
              ),
            ),
            Gap(40.h),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Gap(14.h),
            child,
          ],
        ),
      ),
    );
  }
}
