import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/features/player/data/player_account_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

/// حالة حساب اللاعب — تُجلب عند فتح صفحة اللاعب.
/// { portalEnabled, hasAccount, account: {username, isActive}? }
final playerAccountInfoProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, playerId) async {
  return sl<PlayerAccountService>().getAccount(playerId);
});

/// بطاقة "حساب اللاعب" داخل صفحة اللاعب — نفس الـ Widget لكل المنصات
/// (Android / Windows / Flutter Web).
///
/// - لا حساب → «لا يوجد حساب لهذا اللاعب» + زر إنشاء حساب.
/// - يوجد حساب → اسم المستخدم + الحالة (Active/Disabled) + أزرار الإدارة.
/// - الميزة معطّلة للأكاديمية → البطاقة لا تظهر إطلاقاً.
class PlayerAccountSection extends ConsumerWidget {
  final String playerId;
  final String playerName;
  final bool canEdit;

  const PlayerAccountSection({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canEdit) return const SizedBox.shrink();

    final infoAsync = ref.watch(playerAccountInfoProvider(playerId));
    return infoAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        final portalEnabled = info['portalEnabled'] == true;
        if (!portalEnabled) return const SizedBox.shrink();

        final hasAccount = info['hasAccount'] == true;
        final account = info['account'] as Map<String, dynamic>?;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 0.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_circle_outlined,
                        size: 20.sp, color: AppColors.primary),
                    Gap(8.w),
                    Expanded(
                      child: Text(
                        'حساب اللاعب',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                            ),
                      ),
                    ),
                    if (hasAccount && account != null)
                      _StatusChip(isActive: account['isActive'] == true),
                  ],
                ),
                Gap(12.h),
                if (!hasAccount)
                  _NoAccountBody(
                    playerId: playerId,
                    playerName: playerName,
                  )
                else if (account != null)
                  _AccountBody(
                    playerId: playerId,
                    playerName: playerName,
                    username: account['username'] as String? ?? '',
                    isActive: account['isActive'] == true,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── لا يوجد حساب ────────────────────────────────────────────────────────────

class _NoAccountBody extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;
  const _NoAccountBody({required this.playerId, required this.playerName});

  @override
  ConsumerState<_NoAccountBody> createState() => _NoAccountBodyState();
}

class _NoAccountBodyState extends ConsumerState<_NoAccountBody> {
  bool _busy = false;

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final created =
          await sl<PlayerAccountService>().createAccount(widget.playerId);
      if (!mounted) return;
      ref.invalidate(playerAccountInfoProvider(widget.playerId));
      await AccountCredentialsDialog.show(
        context,
        title: 'تم إنشاء الحساب بنجاح',
        username: created['username'] as String? ?? '',
        password: created['password'] as String? ?? '',
        playerName: widget.playerName,
      );
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'لا يوجد حساب لهذا اللاعب.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.grey500),
        ),
        Gap(12.h),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          onPressed: _busy ? null : _create,
          icon: _busy
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white),
                )
              : const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('إنشاء حساب'),
        ),
      ],
    );
  }
}

// ─── يوجد حساب ───────────────────────────────────────────────────────────────

class _AccountBody extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;
  final String username;
  final bool isActive;

  const _AccountBody({
    required this.playerId,
    required this.playerName,
    required this.username,
    required this.isActive,
  });

  @override
  ConsumerState<_AccountBody> createState() => _AccountBodyState();
}

class _AccountBodyState extends ConsumerState<_AccountBody> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ref.invalidate(playerAccountInfoProvider(widget.playerId));
      }
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    final password = await _ChangePasswordDialog.show(context);
    if (password == null) return;
    await _run(() async {
      await sl<PlayerAccountService>()
          .changePassword(widget.playerId, password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  Future<void> _resetPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('إعادة إنشاء كلمة المرور'),
        content: const Text(
            'سيتم توليد كلمة مرور عشوائية جديدة وإلغاء كلمة المرور الحالية. متابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('متابعة')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      final data =
          await sl<PlayerAccountService>().resetPassword(widget.playerId);
      if (mounted) {
        await AccountCredentialsDialog.show(
          context,
          title: 'تم إعادة إنشاء كلمة المرور',
          username: data['username'] as String? ?? widget.username,
          password: data['password'] as String? ?? '',
          playerName: widget.playerName,
        );
      }
    });
  }

  Future<void> _toggle() async {
    final disabling = widget.isActive;
    if (disabling) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text('تعطيل الحساب'),
          content: const Text(
              'لن يستطيع اللاعب تسجيل الدخول بعد التعطيل. متابعة؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تعطيل'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _run(() async {
      await sl<PlayerAccountService>()
          .toggleAccount(widget.playerId, isActive: !widget.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(disabling ? 'تم تعطيل الحساب' : 'تم تفعيل الحساب'),
            backgroundColor:
                disabling ? AppColors.grey700 : AppColors.success,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // اسم المستخدم
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اسم المستخدم',
                  style:
                      TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
              Gap(4.h),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.username,
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w800),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  IconButton(
                    tooltip: 'نسخ اسم المستخدم',
                    icon: Icon(Icons.copy, size: 18.sp),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: widget.username));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تم نسخ اسم المستخدم')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Gap(12.h),
        if (_busy)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('تغيير كلمة المرور'),
                ),
              ),
              Gap(8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetPassword,
                  icon: const Icon(Icons.autorenew, size: 18),
                  label: const Text('إعادة إنشاء كلمة مرور'),
                ),
              ),
            ],
          ),
          Gap(8.h),
          widget.isActive
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  onPressed: _toggle,
                  icon: const Icon(Icons.block_outlined, size: 18),
                  label: const Text('تعطيل الحساب'),
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: _toggle,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('تفعيل الحساب'),
                ),
        ],
      ],
    );
  }
}

// ─── شارة الحالة ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isActive ? 'Active' : 'Disabled',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 12.sp),
      ),
    );
  }
}

// ─── نافذة تغيير كلمة المرور ─────────────────────────────────────────────────

class _ChangePasswordDialog {
  static Future<String?> show(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('تغيير كلمة المرور'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => (v == null || v.length < 6)
                    ? 'كلمة المرور 6 أحرف على الأقل'
                    : null,
              ),
              Gap(8.h),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                validator: (v) => v != passwordController.text
                    ? 'كلمتا المرور غير متطابقتين'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, passwordController.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─── نافذة بيانات الدخول (إنشاء/إعادة إنشاء) ─────────────────────────────────

/// تعرض username/password مرة واحدة مع أزرار:
/// Copy Username / Copy Password / Share.
class AccountCredentialsDialog {
  AccountCredentialsDialog._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String username,
    required String password,
    String playerName = '',
  }) async {
    final shareText =
        'بيانات دخول اللاعب${playerName.isNotEmpty ? ' $playerName' : ''} '
        'على تطبيق Hurghada Winners:\n'
        'اسم المستخدم: $username\n'
        'كلمة المرور: $password';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            Gap(8.w),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _credRow('اسم المستخدم', username),
            Gap(10.h),
            _credRow('كلمة المرور', password),
            Gap(12.h),
            Text('احفظ هذه البيانات — لن تظهر كلمة المرور مرة أخرى.',
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
            Gap(12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: [
                _actionChip(
                  ctx,
                  icon: Icons.copy,
                  label: 'Copy Username',
                  onTap: () => _copy(ctx, username, 'تم نسخ اسم المستخدم'),
                ),
                _actionChip(
                  ctx,
                  icon: Icons.copy,
                  label: 'Copy Password',
                  onTap: () => _copy(ctx, password, 'تم نسخ كلمة المرور'),
                ),
                _actionChip(
                  ctx,
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () => Share.share(shareText),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  static Future<void> _copy(
      BuildContext ctx, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  static Widget _actionChip(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16.sp, color: AppColors.primary),
      label: Text(label, style: TextStyle(fontSize: 12.sp)),
      onPressed: onTap,
    );
  }

  static Widget _credRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
          Gap(4.h),
          SelectableText(value,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
              textDirection: TextDirection.ltr),
        ],
      ),
    );
  }
}

// ─── عرض الأخطاء ─────────────────────────────────────────────────────────────

void _showError(BuildContext context, Object e) {
  final msg = e is AppException ? e.message : 'حدث خطأ غير متوقع';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.error),
  );
}
