import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/arab_countries.dart';
import 'package:hurghada_winners/core/constants/sports_constants.dart';
import 'package:hurghada_winners/core/utils/currency_utils.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/core/utils/local_image/local_image.dart';
import 'package:hurghada_winners/features/academy_registration/data/academy_registration_service.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Wizard إنشاء أكاديمية جديدة (3 خطوات) — Nosait SaaS.
class AcademyRegistrationWizardScreen extends ConsumerStatefulWidget {
  const AcademyRegistrationWizardScreen({super.key});

  @override
  ConsumerState<AcademyRegistrationWizardScreen> createState() =>
      _AcademyRegistrationWizardScreenState();
}

class _AcademyRegistrationWizardScreenState
    extends ConsumerState<AcademyRegistrationWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _submitting = false;

  final _academyName = TextEditingController();
  final _adminName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _password = TextEditingController();
  String _sport = SportsConstants.defaultSports.first;
  ArabCountry _country = arabCountryDefault; // يحدّد العملة وكود الأرقام
  bool _obscure = true;
  bool _acceptedTerms = false;
  String? _logoPath;

  @override
  void dispose() {
    _academyName.dispose();
    _adminName.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (img != null) setState(() => _logoPath = img.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر اختيار الشعار — يمكنك تخطّيه')),
        );
      }
    }
  }

  void _next() {
    if (_step == 0) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }
    if (_step < 2) {
      setState(() => _step += 1);
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step -= 1);
  }

  Future<void> _submit() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب الموافقة على الشروط للمتابعة')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await sl<AcademyRegistrationService>().register(
        academyName: _academyName.text.trim(),
        adminName: _adminName.text.trim(),
        // الرقم يُرسَل دولياً: كود الدولة المختارة + الرقم المحلي.
        phone: buildInternationalNumber(_country, _phone.text),
        email: _email.text.trim(),
        city: _city.text.trim(),
        sport: _sport,
        password: _password.text,
        currency: _country.currencyCode, // العملة مشتقّة من الدولة
        logoPath: _logoPath,
      );
      // تسجيل الدخول تلقائياً تم داخل الخدمة — نعيد تحميل حالة المصادقة.
      await ref.read(authStateProvider.notifier).reload();
      if (!mounted) return;
      final user = ref.read(authStateProvider).valueOrNull?.user;
      if (user?.academyId != null) {
        context.go(AppRoutes.playersList.replaceFirst(':id', user!.academyId!));
      } else {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppException ? e.message : 'فشل إنشاء الأكاديمية';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء أكاديمية جديدة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560.w),
            child: Column(
              children: [
                _StepIndicator(current: _step),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.r),
                    child: _buildStep(),
                  ),
                ),
                _buildNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      default:
        return _buildStep3();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(_academyName, 'اسم الأكاديمية', Icons.business_outlined),
          Gap(12.h),
          _field(_adminName, 'اسم المدير', Icons.person_outline),
          Gap(12.h),
          _countryField(),
          Gap(12.h),
          _phoneField(),
          Gap(12.h),
          _field(_email, 'البريد الإلكتروني', Icons.email_outlined,
              keyboard: TextInputType.emailAddress, ltr: true, isEmail: true),
          Gap(12.h),
          _field(_city, 'المدينة', Icons.location_city_outlined),
          Gap(12.h),
          DropdownButtonFormField<String>(
            initialValue: _sport,
            decoration: const InputDecoration(
              labelText: 'نوع الرياضة',
              prefixIcon: Icon(Icons.sports_outlined),
            ),
            items: SportsConstants.defaultSports
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _sport = v ?? _sport),
          ),
          Gap(12.h),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              if (v.length < 8) return 'كلمة المرور 8 أحرف على الأقل';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Text('رفع شعار الأكاديمية (اختياري)',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
        Gap(20.h),
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.grey300, width: 2),
            ),
            child: _logoPath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40.sp, color: AppColors.grey500),
                      Gap(8.h),
                      const Text('اختر شعاراً', style: TextStyle(color: AppColors.grey500)),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(18.r),
                    child: Image(
                      image: pickedImageProvider(_logoPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        if (_logoPath != null) ...[
          Gap(12.h),
          TextButton.icon(
            onPressed: () => setState(() => _logoPath = null),
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('إزالة', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الموافقة على الشروط',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
        Gap(12.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.grey200),
          ),
          child: const Text(
            'بإنشائك أكاديمية على منصة Hurghada Winners فإنك توافق على شروط الاستخدام وسياسة '
            'الخصوصية. تبدأ أكاديميتك بفترة تجريبية مجانية لمدة 7 أيام وبحدّ أقصى '
            '7 لاعبين. لتفعيل اشتراك كامل يمكنك التواصل مع إدارة Hurghada Winners.',
            style: TextStyle(height: 1.7, color: AppColors.grey700),
          ),
        ),
        Gap(12.h),
        CheckboxListTile(
          value: _acceptedTerms,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('أوافق على الشروط والأحكام'),
          onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
        ),
      ],
    );
  }

  Widget _buildNav() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : _back,
                child: const Text('السابق'),
              ),
            ),
          if (_step > 0) Gap(12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : (_step < 2 ? _next : _submit),
              child: _submitting
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.white),
                    )
                  : Text(_step < 2 ? 'التالي' : 'إنشاء الأكاديمية'),
            ),
          ),
        ],
      ),
    );
  }

  /// اختيار الدولة — يحدّد عملة الأكاديمية وكود الأرقام. يعرض العلم + الاسم +
  /// العملة + الكود الدولي داخل القائمة.
  Widget _countryField() {
    return DropdownButtonFormField<ArabCountry>(
      initialValue: _country,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'الدولة (تحدّد العملة وكود الهاتف)',
        prefixIcon: Icon(Icons.public_outlined),
      ),
      items: arabCountries
          .map((c) => DropdownMenuItem<ArabCountry>(
                value: c,
                child: Text(
                  '${c.flag}  ${c.nameAr} — ${CurrencyUtils.label(c.currencyCode)} (+${c.dialCode})',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (c) => setState(() => _country = c ?? _country),
    );
  }

  /// حقل الهاتف — يُدخِل المستخدم الرقم المحلي فقط، وكود الدولة يظهر كبادئة
  /// ثابتة ويُضاف تلقائياً عند الإرسال.
  Widget _phoneField() {
    return TextFormField(
      controller: _phone,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: 'رقم الهاتف / واتساب',
        prefixIcon: const Icon(Icons.phone_outlined),
        prefixText: '+${_country.dialCode} ',
        hintText: '1001234567',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'مطلوب';
        final digits = v.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.length < 6) return 'رقم غير صحيح';
        return null;
      },
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool ltr = false,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      textDirection: ltr ? TextDirection.ltr : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'مطلوب';
        if (isEmail && !RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v.trim())) {
          return 'بريد إلكتروني غير صحيح';
        }
        return null;
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= current;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: active ? AppColors.primary : AppColors.grey300,
                  child: Text('${i + 1}',
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                ),
                Gap(6.w),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < current ? AppColors.primary : AppColors.grey300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
