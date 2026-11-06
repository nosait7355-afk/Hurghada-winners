import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/sports_constants.dart';
import 'package:hurghada_winners/core/utils/local_image/local_image.dart';
import 'package:hurghada_winners/core/widgets/multi_select_chips.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/staff/domain/entities/staff_entity.dart';
import 'package:hurghada_winners/features/staff/presentation/providers/staff_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddEditStaffScreen extends ConsumerStatefulWidget {
  final String academyId;
  final StaffEntity? staff;

  const AddEditStaffScreen({super.key, required this.academyId, this.staff});

  bool get isEdit => staff != null;

  @override
  ConsumerState<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends ConsumerState<AddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _fullNameController =
      TextEditingController(text: widget.staff?.fullName);
  late final _positionController =
      TextEditingController(text: widget.staff?.position);
  late final _phoneController =
      TextEditingController(text: widget.staff?.phone);
  late final _emailController =
      TextEditingController(text: widget.staff?.email);
  // المرتب = سعر التمرينة × أيام الحضور المسجّلة في الشهر.
  late final _sessionRateController = TextEditingController(
      text: widget.staff?.sessionRate?.toStringAsFixed(0));

  DateTime? _hireDate;
  List<String> _workingDays = const [];
  XFile? _pickedImage;
  bool _isLoading = false;

  final _dateFormat = DateFormat('dd/MM/yyyy', 'ar');

  /// الحسابات الإدارية المحدودة (canViewReports=false) لا ترى الحقول المالية
  /// ولا ترسلها — الخادم يحجبها ويثبّت إعدادات محايدة بدلاً منها.
  bool get _canSeeSalary =>
      ref.read(authStateProvider).valueOrNull?.user?.canViewReports != false;

  @override
  void initState() {
    super.initState();
    _hireDate = widget.staff?.hireDate ?? DateTime.now();
    _workingDays = widget.staff?.workingDays ?? const [];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _sessionRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _selectHireDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _hireDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_workingDays.isEmpty) {
      _showSnack('الرجاء اختيار أيام العمل', AppColors.error);
      return;
    }
    if (_hireDate == null) {
      _showSnack('الرجاء اختيار تاريخ التعيين', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    final sessionRate = _canSeeSalary
        ? double.tryParse(_sessionRateController.text.trim())
        : null;

    String? error;
    if (widget.isEdit) {
      error = await ref.read(staffProvider.notifier).updateStaff(
            id: widget.staff!.id,
            fullName: _fullNameController.text.trim(),
            position: _positionController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            hireDate: _hireDate,
            sessionRate: sessionRate,
            workingDays: _workingDays,
            photoPath: _pickedImage?.path,
          );
    } else {
      error = await ref.read(staffProvider.notifier).createStaff(
            fullName: _fullNameController.text.trim(),
            position: _positionController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            hireDate: _hireDate!,
            sessionRate: sessionRate,
            workingDays: _workingDays,
            photoPath: _pickedImage?.path,
            academyId: widget.academyId,
          );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showSnack(error, AppColors.error);
    } else {
      _showSnack(
          widget.isEdit ? 'تم تحديث بيانات الموظف' : 'تم إضافة الموظف بنجاح',
          AppColors.success);
      Navigator.of(context).pop();
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(widget.isEdit ? 'تعديل الموظف' : 'إضافة موظف'),
          centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50.r,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: _pickedImage != null
                        ? pickedImageProvider(_pickedImage!.path)
                        : (widget.staff?.photoUrl != null
                            ? CachedNetworkImageProvider(
                                widget.staff!.photoUrl!) as ImageProvider
                            : null),
                    child:
                        _pickedImage == null && widget.staff?.photoUrl == null
                            ? Icon(Icons.person_add_outlined,
                                color: AppColors.primary, size: 40.sp)
                            : null,
                  ),
                ),
              ),
              Gap(24.h),
              _label('الاسم الكامل'),
              Gap(6.h),
              TextFormField(
                controller: _fullNameController,
                decoration: _decoration(),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'الاسم مطلوب (حرفين على الأقل)'
                    : null,
              ),
              Gap(16.h),
              _label('الوظيفة'),
              Gap(6.h),
              TextFormField(
                controller: _positionController,
                decoration: _decoration(hint: 'مثال: مدرب، إداري، محاسب'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الوظيفة مطلوبة' : null,
              ),
              Gap(16.h),
              _label('رقم الهاتف'),
              Gap(6.h),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _decoration(),
                validator: (v) => (v == null || v.trim().length < 7)
                    ? 'رقم الهاتف غير صحيح'
                    : null,
              ),
              Gap(16.h),
              _label('البريد الإلكتروني (اختياري)'),
              Gap(6.h),
              TextFormField(
                  controller: _emailController, decoration: _decoration()),
              Gap(16.h),
              _label('تاريخ التعيين'),
              Gap(6.h),
              GestureDetector(
                onTap: _selectHireDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    key: ValueKey(_hireDate),
                    initialValue:
                        _hireDate != null ? _dateFormat.format(_hireDate!) : '',
                    decoration:
                        _decoration(suffixIcon: Icons.calendar_today_outlined),
                  ),
                ),
              ),
              Gap(16.h),
              if (_canSeeSalary) ...[
                _label('سعر التمرينة'),
                Gap(6.h),
                TextFormField(
                  controller: _sessionRateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration(
                      hint: 'المرتب = سعر التمرينة × عدد أيام الحضور'),
                  validator: (v) {
                    final value = double.tryParse((v ?? '').trim());
                    if (value == null || value < 0) return 'أدخل سعر التمرينة';
                    return null;
                  },
                ),
                Gap(16.h),
              ],
              _label('أيام العمل'),
              Gap(6.h),
              MultiSelectChips(
                options: SportsConstants.weekDays,
                selected: _workingDays,
                onChanged: (days) => setState(() => _workingDays = days),
              ),
              Gap(16.h),
              Gap(8.h),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white))
                    : Text(widget.isEdit ? 'حفظ التعديلات' : 'إضافة الموظف',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w700)),
              ),
              Gap(40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.grey700));

  InputDecoration _decoration({String? hint, IconData? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14.sp),
      filled: true,
      fillColor: AppColors.white,
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: AppColors.grey400)
          : null,
      contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.grey200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.grey200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
