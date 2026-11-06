import 'package:hurghada_winners/core/auth/saved_accounts_store.dart';
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/core/widgets/saved_accounts_strip.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// شاشة دخول اللاعب / ولي الأمر (username = nosait00001).
class PlayerLoginScreen extends ConsumerStatefulWidget {
  const PlayerLoginScreen({super.key});

  @override
  ConsumerState<PlayerLoginScreen> createState() => _PlayerLoginScreenState();
}

class _PlayerLoginScreenState extends ConsumerState<PlayerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;
  bool _remember = true;
  List<SavedAccount> _savedAccounts = const [];
  // الحساب المحفوظ الذي بدأ منه الدخول الحالي (لمعالجة كلمة مرور تغيّرت).
  SavedAccount? _loginFromSaved;

  SavedAccountsStore get _store => sl<SavedAccountsStore>();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final accounts = await _store.load(SavedAccountKind.player);
    if (mounted) setState(() => _savedAccounts = accounts);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _submitted = true;
        _loginFromSaved = null;
      });
      ref.read(playerSessionProvider.notifier).login(
            username: _username.text.trim(),
            password: _password.text,
          );
    }
  }

  void _loginWithSaved(SavedAccount account) {
    _username.text = account.username;
    _password.text = account.password;
    setState(() {
      _submitted = true;
      _loginFromSaved = account;
    });
    ref.read(playerSessionProvider.notifier).login(
          username: account.username,
          password: account.password,
        );
  }

  Future<void> _deleteSaved(SavedAccount account) async {
    await _store.remove(SavedAccountKind.player, account.username);
    await _loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen(playerSessionProvider, (_, next) {
      final st = next.valueOrNull;
      if (st?.isAuthenticated == true) {
        // الحفظ بعد نجاح الدخول فقط.
        if (_submitted && (_remember || _loginFromSaved != null)) {
          final p = st?.player;
          _store.upsert(
            SavedAccountKind.player,
            SavedAccount(
              username: _username.text.trim(),
              password: _password.text,
              displayName:
                  SavedAccountsStore.firstName(p?['fullName'] as String? ?? ''),
              imageUrl: p?['image_url'] as String?,
            ),
          );
        }
        context.go(AppRoutes.playerDashboard);
      } else if (!next.isLoading) {
        final fromSaved = _loginFromSaved;
        if (_submitted) {
          setState(() {
            _submitted = false;
            _loginFromSaved = null;
          });
        }
        if (st?.errorMessage != null) {
          // كلمة المرور المحفوظة لم تعد صالحة: نترك اسم المستخدم ونطلب الجديدة.
          if (fromSaved != null) _password.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fromSaved != null
                  ? 'تعذّر الدخول بالحساب المحفوظ، أدخل كلمة المرور الجديدة'
                  : st!.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          ref.read(playerSessionProvider.notifier).clearError();
        }
      }
    });

    final isLoading = _submitted && ref.watch(playerSessionProvider).isLoading;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 440.w),
                child: Column(
                  children: [
                    IconButton(
                      alignment: Alignment.centerRight,
                      onPressed: () => context.go(AppRoutes.welcome),
                      icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    ),
                    Gap(10.h),
                    Icon(Icons.person, size: 64.sp, color: AppColors.white),
                    Gap(10.h),
                    Text('دخول اللاعب',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.white, fontWeight: FontWeight.w800)),
                    Gap(28.h),
                    if (_savedAccounts.isNotEmpty) ...[
                      SavedAccountsStrip(
                        accounts: _savedAccounts,
                        enabled: !isLoading,
                        onSelect: _loginWithSaved,
                        onDelete: _deleteSaved,
                      ),
                      Gap(20.h),
                    ],
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _username,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'رقم الهاتف / اسم المستخدم',
                                hintText: 'nosait00001',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                            ),
                            Gap(14.h),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              onFieldSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'مطلوب' : null,
                            ),
                            Gap(12.h),
                            CheckboxListTile(
                              value: _remember,
                              onChanged: (v) => setState(() => _remember = v ?? false),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.primary,
                              title: Text('حفظ الحساب على هذا الجهاز',
                                  style: TextStyle(fontSize: 14.sp)),
                              subtitle: kIsWeb && _remember
                                  ? Text(
                                      'على المتصفح يُحفظ الحساب في هذا المتصفح فقط. لا تفعّله على جهاز مشترك.',
                                      style: TextStyle(fontSize: 11.sp),
                                    )
                                  : null,
                            ),
                            Gap(10.h),
                            ConstrainedBox(
                              constraints: BoxConstraints(minHeight: 50.h),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _login,
                                child: isLoading
                                    ? SizedBox(
                                        height: 20.h,
                                        width: 20.h,
                                        child: const CircularProgressIndicator(
                                            strokeWidth: 2.5, color: AppColors.white),
                                      )
                                    : Text('تسجيل الدخول',
                                        style: TextStyle(
                                            fontSize: 16.sp, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(18.h),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.playerJoinRequest),
                      icon: const Icon(Icons.person_add_alt_1, color: AppColors.white),
                      label: Text(
                        'تسجيل لاعب جديد',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.white,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => WhatsAppUtils.openSupport(context),
                      icon: const Icon(Icons.support_agent, color: AppColors.white),
                      label: Text(
                        'الدعم الفني',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
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
