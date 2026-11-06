import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:hurghada_winners/core/constants/sports_constants.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/core/utils/local_image/local_image.dart';
import 'package:hurghada_winners/core/widgets/multi_select_chips.dart';
import 'package:hurghada_winners/features/player_portal/data/player_api_service.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// تسجيل ذاتي للاعب جديد (طلب انضمام) — عام، بلا تسجيل دخول سابق.
/// خطوتان: (1) بيانات اللاعب + الفرع + إيصال الدفع، (2) بيانات دخوله
/// (رقم الهاتف + كلمة المرور). عند النجاح يسجَّل دخول اللاعب تلقائياً
/// وينتقل لشاشة "طلبك قيد المراجعة".
class PlayerJoinRequestWizardScreen extends ConsumerStatefulWidget {
  const PlayerJoinRequestWizardScreen({super.key});

  @override
  ConsumerState<PlayerJoinRequestWizardScreen> createState() =>
      _PlayerJoinRequestWizardScreenState();
}

class _PlayerJoinRequestWizardScreenState
    extends ConsumerState<PlayerJoinRequestWizardScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  int _step = 0;
  bool _submitting = false;

  final _fullName = TextEditingController();
  final _parentName = TextEditingController();
  final _parentJob = TextEditingController();
  final _parentPhone = TextEditingController();
  final _playerPhone = TextEditingController();
  final _notes = TextEditingController();
  final _loginPhone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  DateTime? _birthDate;
  String? _relationship;
  BranchInfo? _branch;
  List<String> _attendanceDays = const [];
  XFile? _playerImage;
  XFile? _receiptImage;
  bool _obscure = true;
  bool _obscureConfirm = true;

  final _dateFormat = DateFormat('dd/MM/yyyy', 'ar');

  static const List<String> _relationships = [
    'أب', 'أم', 'أخ', 'أخت', 'جد', 'جدة', 'عم', 'عمة', 'خال', 'خالة', 'وصي',
  ];

  @override
  void dispose() {
    _fullName.dispose();
    _parentName.dispose();
    _parentJob.dispose();
    _parentPhone.dispose();
    _playerPhone.dispose();
    _notes.dispose();
    _loginPhone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 10),
      firstDate: DateTime(now.year - 50),
      lastDate: now,
      helpText: 'اختر التاريخ',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickPlayerImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85,
    );
    if (img != null) setState(() => _playerImage = img);
  }

  Future<void> _pickReceiptImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 90,
    );
    if (img != null) setState(() => _receiptImage = img);
  }

  void _next() {
    if (!(_step1FormKey.currentState?.validate() ?? false)) return;
    if (_birthDate == null) {
      _snack('الرجاء اختيار تاريخ الميلاد');
      return;
    }
    if (_branch == null) {
      _snack('الرجاء اختيار الفرع');
      return;
    }
    if (_playerImage == null) {
      _snack('صورة اللاعب إجبارية');
      return;
    }
    if (_receiptImage == null) {
      _snack('صورة إيصال الدفع مطلوبة');
      return;
    }
    setState(() => _step = 1);
  }

  void _back() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.playerLogin);
    }
  }

  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_step2FormKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await sl<PlayerApiService>().submitJoinRequest(
        academyId: _branch!.academyId,
        fullName: _fullName.text.trim(),
        birthDate: DateFormat('yyyy-MM-dd').format(_birthDate!),
        parentName: _parentName.text.trim(),
        parentRelationship: _relationship!,
        parentJob: _parentJob.text.trim().isEmpty ? null : _parentJob.text.trim(),
        parentPhone: _parentPhone.text.trim(),
        playerPhone: _playerPhone.text.trim().isEmpty ? null : _playerPhone.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        branch: _branch!.name,
        loginPhone: _loginPhone.text.trim(),
        password: _password.text,
        attendanceDays: _attendanceDays,
        imagePath: _playerImage!.path,
        receiptPath: _receiptImage!.path,
      );
      // التوكن اتحفظ جوّه submitJoinRequest — نجيب بيانات الجلسة الرسمية.
      await ref.read(playerSessionProvider.notifier).refreshFromToken();
      if (!mounted) return;
      context.go(AppRoutes.playerPendingApproval);
    } catch (e) {
      final msg = e is AppException ? e.message : 'تعذّر إرسال طلب الانضمام';
      if (mounted) _snack(msg);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _submitting ? null : _back,
                      icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    ),
                    Gap(4.w),
                    Text(
                      'تسجيل لاعب جديد',
                      style: TextStyle(
                        fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _StepIndicator(current: _step),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 520.w),
                    child: Container(
                      margin: EdgeInsets.all(16.r),
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: SingleChildScrollView(
                        child: _step == 0 ? _buildStep1() : _buildStep2(),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.r),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: 50.h,
                  ),
                  child: ElevatedButton(
                    onPressed: _submitting ? null : (_step == 0 ? _next : _submit),
                    child: _submitting
                        ? SizedBox(
                            height: 20.h, width: 20.h,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppColors.white),
                          )
                        : Text(
                            _step == 0 ? 'التالي' : 'إرسال طلب الانضمام',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('بيانات اللاعب', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
          Gap(16.h),
          DropdownButtonFormField<BranchInfo>(
            initialValue: _branch,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'الفرع', prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: AppConstants.branches
                .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                .toList(),
            onChanged: (v) => setState(() => _branch = v),
            validator: (v) => v == null ? 'الرجاء اختيار الفرع' : null,
          ),
          Gap(14.h),
          TextFormField(
            controller: _fullName,
            decoration: const InputDecoration(
              labelText: 'اسم اللاعب', prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'مطلوب';
              if (v.trim().length < 2) return 'الاسم قصير جداً';
              return null;
            },
          ),
          Gap(14.h),
          GestureDetector(
            onTap: _selectDate,
            child: AbsorbPointer(
              child: TextFormField(
                key: ValueKey(_birthDate),
                initialValue: _birthDate != null ? _dateFormat.format(_birthDate!) : '',
                decoration: const InputDecoration(
                  labelText: 'تاريخ الميلاد',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
            ),
          ),
          Gap(14.h),
          TextFormField(
            controller: _parentName,
            decoration: const InputDecoration(
              labelText: 'اسم ولي الأمر', prefixIcon: Icon(Icons.family_restroom_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          Gap(14.h),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            decoration: const InputDecoration(
              labelText: 'صلة القرابة', prefixIcon: Icon(Icons.groups_outlined),
            ),
            items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _relationship = v),
            validator: (v) => v == null ? 'مطلوب' : null,
          ),
          Gap(14.h),
          TextFormField(
            controller: _parentPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم هاتف ولي الأمر', prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'مطلوب';
              if (v.trim().length < 7) return 'رقم غير صحيح';
              return null;
            },
          ),
          Gap(14.h),
          TextFormField(
            controller: _playerPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم هاتف اللاعب (اختياري)', prefixIcon: Icon(Icons.smartphone_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (v.trim().length < 7) return 'رقم غير صحيح';
              return null;
            },
          ),
          Gap(14.h),
          TextFormField(
            controller: _parentJob,
            decoration: const InputDecoration(
              labelText: 'وظيفة ولي الأمر (اختياري)', prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          Gap(14.h),
          Text('أيام الحضور (اختياري)',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.grey700)),
          Gap(6.h),
          MultiSelectChips(
            options: SportsConstants.weekDays,
            selected: _attendanceDays,
            onChanged: (days) => setState(() => _attendanceDays = days),
          ),
          Gap(14.h),
          TextFormField(
            controller: _notes,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
          ),
          Gap(8.h),
          _imagePickerTile(
            label: 'صورة اللاعب (إجباري)',
            file: _playerImage,
            onTap: _pickPlayerImage,
            onClear: () => setState(() => _playerImage = null),
            required: true,
          ),
          Gap(14.h),
          _imagePickerTile(
            label: 'صورة إيصال الدفع (مطلوب)',
            file: _receiptImage,
            onTap: _pickReceiptImage,
            onClear: () => setState(() => _receiptImage = null),
            required: true,
          ),
        ],
      ),
    );
  }

  Widget _imagePickerTile({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool required = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: (required && file == null) ? AppColors.error.withValues(alpha: 0.4) : AppColors.grey200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: AppColors.primaryContainer,
              ),
              clipBehavior: Clip.antiAlias,
              child: file == null
                  ? Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 22.sp)
                  : Image(
                      image: pickedImageProvider(file.path),
                      fit: BoxFit.cover,
                    ),
            ),
            Gap(12.w),
            Expanded(
              child: Text(
                file == null ? label : file.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.sp, color: AppColors.grey700),
              ),
            ),
            if (file != null)
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.error),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('بيانات الدخول', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
          Gap(6.h),
          Text(
            'هتستخدم رقم الهاتف وكلمة المرور دي لتسجيل الدخول لاحقاً.',
            style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey500),
          ),
          Gap(16.h),
          TextFormField(
            controller: _loginPhone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_iphone_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'مطلوب';
              if (v.trim().length < 7) return 'رقم غير صحيح';
              return null;
            },
          ),
          Gap(14.h),
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
          Gap(14.h),
          TextFormField(
            controller: _confirmPassword,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v != _password.text) return 'كلمتا المرور غير متطابقتين';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      child: Row(
        children: List.generate(2, (i) {
          final active = i <= current;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13.r,
                  backgroundColor: active ? AppColors.white : AppColors.white.withValues(alpha: 0.35),
                  child: Text('${i + 1}',
                      style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                ),
                Gap(6.w),
                if (i == 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: current > 0 ? AppColors.white : AppColors.white.withValues(alpha: 0.35),
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
