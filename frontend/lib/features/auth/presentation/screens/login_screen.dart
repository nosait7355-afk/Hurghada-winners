import 'package:hurghada_winners/core/auth/saved_accounts_store.dart';
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/widgets/saved_accounts_strip.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/core/utils/privacy_launcher.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  // "حفظ الحساب على هذا الجهاز" — مفعّل افتراضياً، ويتذكر آخر اختيار.
  bool _rememberMe = true;
  bool _hasSubmitted = false;
  static const _kRememberKey = 'remember_me';
  List<SavedAccount> _savedAccounts = const [];
  // الحساب المحفوظ الذي بدأ منه الدخول الحالي (لمعالجة كلمة مرور تغيّرت).
  SavedAccount? _loginFromSaved;
  SavedAccountsStore get _store => sl<SavedAccountsStore>();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _store.load(SavedAccountKind.admin);
    if (!mounted) return;
    setState(() {
      _rememberMe = prefs.getBool(_kRememberKey) ?? true;
      _savedAccounts = accounts;
    });
  }

  Future<void> _saveRememberChoice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberKey, _rememberMe);
  }

  void _loginWithSaved(SavedAccount account) {
    _emailController.text = account.username;
    _passwordController.text = account.password;
    setState(() {
      _hasSubmitted = true;
      _loginFromSaved = account;
    });
    ref.read(authStateProvider.notifier).login(
          email: account.username,
          password: account.password,
        );
  }

  Future<void> _deleteSaved(SavedAccount account) async {
    await _store.remove(SavedAccountKind.admin, account.username);
    final accounts = await _store.load(SavedAccountKind.admin);
    if (mounted) setState(() => _savedAccounts = accounts);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _hasSubmitted = true;
        _loginFromSaved = null;
      });
      _saveRememberChoice();
      ref.read(authStateProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  /// Opens WhatsApp to the company number for account creation / inquiry.
  /// This is a contact channel only — it does NOT create an account in-app.
  Future<void> _contactCompany() async {
    final ok = await WhatsAppUtils.open(
      AppConstants.companyWhatsappNumber,
      message: AppConstants.contactDefaultMessage,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح واتساب'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openPrivacyPolicy() => openPrivacyPolicy(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen(authStateProvider, (_, next) {
      final st = next.valueOrNull;
      debugPrint('[LOGIN] authState changed: isLoading=${next.isLoading} isAuthenticated=${st?.isAuthenticated} error=${st?.errorMessage}');
      if (st?.isAuthenticated == true) {
        debugPrint('[LOGIN] NAVIGATION START → going to home/players');
        final user = st?.user;
        // الحفظ من هنا (بعد نجاح الدخول فقط) — دخول من كارت محفوظ يحدّث
        // بياناته دائماً، ودخول يدوي يُحفظ إن كان الخيار مفعّلاً.
        if (_hasSubmitted && (_rememberMe || _loginFromSaved != null)) {
          _store.upsert(
            SavedAccountKind.admin,
            SavedAccount(
              username: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: SavedAccountsStore.firstName(user?.name ?? ''),
            ),
          );
        }
        if (user?.isAdmin == true && user?.academyId != null) {
          context.go(AppRoutes.playersList.replaceFirst(':id', user!.academyId!));
        } else {
          context.go(AppRoutes.home);
        }
        debugPrint('[LOGIN] NAVIGATION COMPLETE');
      } else if (!next.isLoading) {
        final fromSaved = _loginFromSaved;
        if (_hasSubmitted) {
          setState(() {
            _hasSubmitted = false;
            _loginFromSaved = null;
          });
        }
        if (st?.errorMessage != null) {
          // كلمة المرور المحفوظة لم تعد صالحة: نترك البريد ونطلب الجديدة.
          if (fromSaved != null) _passwordController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fromSaved != null
                  ? 'تعذّر الدخول بالحساب المحفوظ، أدخل كلمة المرور الجديدة'
                  : st!.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          ref.read(authStateProvider.notifier).clearError();
        }
      }
    });

    final authAsync = ref.watch(authStateProvider);
    // يظهر loading فقط لو المستخدم ضغط الزر بالفعل + الـ provider شغال فعلاً
    final isLoading = _hasSubmitted && authAsync.isLoading;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondary, AppColors.secondaryDark],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                child: Column(
                  children: [
                    // زر الرجوع لواجهة البرنامج (شاشة الترحيب)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => context.go(AppRoutes.welcome),
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.white),
                        label: Text(
                          'رجوع',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    Gap(16.h),
                    // Logo — شعار التطبيق الرسمي داخل بطاقة بيضاء ليظهر بوضوح
                    // فوق الخلفية الداكنة (الشعار نفسه يحمل اسم Hurghada Winners).
                    Container(
                      width: 132.w,
                      height: 132.w,
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(26.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo2026.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Gap(16.h),
                    Text(
                      'نظام الإدارة الاحترافي',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Gap(32.h),
                    if (_savedAccounts.isNotEmpty) ...[
                      SavedAccountsStrip(
                        accounts: _savedAccounts,
                        enabled: !isLoading,
                        onSelect: _loginWithSaved,
                        onDelete: _deleteSaved,
                      ),
                      Gap(20.h),
                    ],
                    // Card
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.welcomeBack,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Gap(4.h),
                            Text(
                              AppStrings.loginSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.grey500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Gap(28.h),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: AppStrings.email,
                                prefixIcon: Icon(Icons.email_outlined),
                                hintText: 'example@academy.com',
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppStrings.required;
                                if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v)) {
                                  return AppStrings.invalidEmail;
                                }
                                return null;
                              },
                            ),
                            Gap(14.h),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: AppStrings.password,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppStrings.required;
                                if (v.length < 8) return AppStrings.passwordTooShort;
                                return null;
                              },
                            ),
                            Gap(16.h),
                            // Remember me checkbox
                            Row(
                              children: [
                                SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? false),
                                  ),
                                ),
                                Gap(8.w),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _rememberMe = !_rememberMe),
                                  child: Text(
                                    'حفظ الحساب على هذا الجهاز',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.grey700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (kIsWeb && _rememberMe)
                              Padding(
                                padding: EdgeInsets.only(top: 6.h),
                                child: Text(
                                  'على المتصفح يُحفظ الحساب في هذا المتصفح فقط. لا تفعّله على جهاز مشترك.',
                                  style: TextStyle(
                                      fontSize: 11.sp, color: AppColors.grey500),
                                ),
                              ),
                            Gap(20.h),
                            ConstrainedBox(
                              constraints: BoxConstraints(minHeight: 50.h),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
                                child: isLoading
                                    ? SizedBox(
                                        height: 20.h,
                                        width: 20.h,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Text(
                                        AppStrings.loginButton,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(20.h),
                    // تواصل مع الدعم — يفتح واتساب الشركة
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 50.h),
                      child: OutlinedButton.icon(
                        onPressed: _contactCompany,
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: AppColors.white),
                        label: Text(
                          'تواصل مع الدعم',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.white.withValues(alpha: 0.7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                    Gap(12.h),
                    // Privacy policy link
                    TextButton(
                      onPressed: _openPrivacyPolicy,
                      child: Text(
                        'سياسة الخصوصية',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.white.withValues(alpha: 0.85),
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
