import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/core/constants/sports_constants.dart';
import 'package:hurghada_winners/core/utils/local_image/local_image.dart';
import 'package:hurghada_winners/core/widgets/multi_select_chips.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/groups/presentation/providers/groups_provider.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/presentation/providers/player_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditPlayerScreen extends ConsumerStatefulWidget {
  final PlayerEntity player;
  final String academyId;

  const EditPlayerScreen({
    super.key,
    required this.player,
    required this.academyId,
  });

  @override
  ConsumerState<EditPlayerScreen> createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends ConsumerState<EditPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _parentJobController;
  late final TextEditingController _parentPhoneController;
  late final TextEditingController _playerPhoneController;
  late final TextEditingController _notesController;

  DateTime? _birthDate;
  String? _selectedRelationship;
  String? _selectedSport;
  String? _selectedGroupId;
  late List<String> _selectedAttendanceDays;
  XFile? _pickedImage;
  bool _isLoading = false;

  final _dateFormat = DateFormat('dd/MM/yyyy', 'ar');

  static const List<String> _relationships = [
    'أب',
    'أم',
    'أخ',
    'أخت',
    'جد',
    'جدة',
    'عم',
    'عمة',
    'خال',
    'خالة',
    'وصي',
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.player.fullName);
    _parentNameController =
        TextEditingController(text: widget.player.parentName);
    _parentJobController =
        TextEditingController(text: widget.player.parentJob ?? '');
    _parentPhoneController =
        TextEditingController(text: widget.player.parentPhone);
    _playerPhoneController =
        TextEditingController(text: widget.player.playerPhone ?? '');
    _notesController =
        TextEditingController(text: widget.player.notes ?? '');
    _birthDate = widget.player.birthDate;
    _selectedRelationship = widget.player.parentRelationship;
    _selectedSport = widget.player.sport;
    _selectedGroupId = widget.player.groupId;
    _selectedAttendanceDays = List<String>.from(widget.player.attendanceDays);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _parentNameController.dispose();
    _parentJobController.dispose();
    _parentPhoneController.dispose();
    _playerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
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
            Text(
              AppStrings.changeImage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Gap(8.h),
            ListTile(
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.photo_library_outlined,
                    color: AppColors.primary, size: 20.sp),
              ),
              title: const Text(AppStrings.fromGallery),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary, size: 20.sp),
              ),
              title: const Text(AppStrings.fromCamera),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            Gap(8.h),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 10),
      firstDate: DateTime(now.year - 50),
      lastDate: now,
      helpText: AppStrings.selectDate,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار تاريخ الميلاد'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final academy = ref.read(academyByIdProvider(widget.academyId)).valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    if (isMultiSport && (_selectedSport == null || _selectedSport!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الرياضة'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(playersProvider.notifier).updatePlayer(
          id: widget.player.id,
          fullName: _fullNameController.text.trim(),
          birthDate: _birthDate,
          parentName: _parentNameController.text.trim(),
          parentRelationship: _selectedRelationship,
          parentJob: _parentJobController.text.trim().isEmpty
              ? null
              : _parentJobController.text.trim(),
          parentPhone: _parentPhoneController.text.trim(),
          // Always send (even empty) so clearing the field removes the saved number
          playerPhone: _playerPhoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          sport: isMultiSport ? _selectedSport : null,
          attendanceDays: _selectedAttendanceDays,
          imagePath: _pickedImage?.path,
          groupId: _selectedGroupId ?? '',
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

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
          content: Text(AppStrings.playerUpdated),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final academy = ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    final sports = academy?.sports ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.editPlayer),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerSheet,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60.r,
                        backgroundColor: AppColors.primaryContainer,
                        child: _pickedImage != null
                            ? ClipOval(
                                child: Image(
                                  image:
                                      pickedImageProvider(_pickedImage!.path),
                                  width: 120.r,
                                  height: 120.r,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (widget.player.imageUrl != null &&
                                    widget.player.imageUrl!.isNotEmpty)
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: widget.player.imageUrl!,
                                      width: 120.r,
                                      height: 120.r,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                        size: 48.sp,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 48.sp,
                                  ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppColors.white,
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Gap(8.h),
              Center(
                child: Text(
                  AppStrings.changeImage,
                  style: TextStyle(
                      fontSize: 13.sp, color: AppColors.grey500),
                ),
              ),

              Gap(24.h),

              // Full name
              _buildLabel(AppStrings.playerName),
              Gap(6.h),
              TextFormField(
                controller: _fullNameController,
                decoration: _inputDecoration(hint: 'أدخل الاسم الكامل'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppStrings.required;
                  if (v.trim().length < 2) {
                    return 'الاسم يجب أن يكون حرفين على الأقل';
                  }
                  if (v.trim().length > 150) return 'الاسم طويل جداً';
                  return null;
                },
              ),

              Gap(16.h),

              // Birth date
              _buildLabel(AppStrings.birthDate),
              Gap(6.h),
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    key: ValueKey(_birthDate),
                    initialValue: _birthDate != null
                        ? _dateFormat.format(_birthDate!)
                        : '',
                    decoration: _inputDecoration(
                      hint: AppStrings.selectDate,
                      suffixIcon: Icons.calendar_today_outlined,
                    ),
                    validator: (_) =>
                        _birthDate == null ? AppStrings.required : null,
                  ),
                ),
              ),

              Gap(16.h),

              // Parent name
              _buildLabel(AppStrings.parentName),
              Gap(6.h),
              TextFormField(
                controller: _parentNameController,
                decoration: _inputDecoration(hint: 'أدخل اسم ولي الأمر'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppStrings.required;
                  if (v.trim().length < 2) {
                    return 'الاسم يجب أن يكون حرفين على الأقل';
                  }
                  if (v.trim().length > 100) return 'الاسم طويل جداً';
                  return null;
                },
              ),

              Gap(16.h),

              // Relationship dropdown
              _buildLabel(AppStrings.parentRelationship),
              Gap(6.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedRelationship,
                decoration: _inputDecoration(hint: 'اختر صلة القرابة'),
                items: _relationships
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedRelationship = val),
                validator: (v) =>
                    v == null ? AppStrings.required : null,
              ),

              Gap(16.h),

              // Sport (multi-sport academies only)
              if (isMultiSport) ...[
                _buildLabel('الرياضة'),
                Gap(6.h),
                DropdownButtonFormField<String>(
                  initialValue:
                      sports.contains(_selectedSport) ? _selectedSport : null,
                  decoration: _inputDecoration(hint: 'اختر الرياضة'),
                  items: sports
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSport = val),
                  validator: (v) => v == null ? AppStrings.required : null,
                ),
                Gap(16.h),
              ],

              // Group (optional — clearing means "no group")
              _buildLabel('المجموعة (اختياري)'),
              Gap(6.h),
              Consumer(
                builder: (context, ref, _) {
                  // كل مجموعات الأكاديمية — مستقلة تماماً عن الرياضة.
                  final groupsAsync = ref.watch(groupsByAcademyProvider(
                    (
                      academyId: widget.academyId,
                      sportId: null,
                    ),
                  ));
                  return groupsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text(
                      'تعذر تحميل المجموعات',
                      style: TextStyle(color: AppColors.error, fontSize: 12.sp),
                    ),
                    data: (groups) {
                      final currentGroupValid =
                          groups.any((g) => g.id == _selectedGroupId);
                      return DropdownButtonFormField<String>(
                        initialValue: currentGroupValid ? _selectedGroupId : null,
                        decoration: _inputDecoration(hint: 'اختر المجموعة'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('بدون مجموعة')),
                          ...groups.map((g) => DropdownMenuItem(
                              value: g.id, child: Text(g.name))),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedGroupId = val),
                      );
                    },
                  );
                },
              ),
              Gap(16.h),

              // Attendance days (optional)
              _buildLabel('أيام الحضور (اختياري)'),
              Gap(6.h),
              MultiSelectChips(
                options: SportsConstants.weekDays,
                selected: _selectedAttendanceDays,
                onChanged: (days) =>
                    setState(() => _selectedAttendanceDays = days),
              ),

              Gap(16.h),

              // Parent job (optional)
              _buildLabel('${AppStrings.parentJob} (اختياري)'),
              Gap(6.h),
              TextFormField(
                controller: _parentJobController,
                decoration: _inputDecoration(hint: 'أدخل مهنة ولي الأمر'),
              ),

              Gap(16.h),

              // Parent phone
              _buildLabel(AppStrings.parentPhone),
              Gap(6.h),
              TextFormField(
                controller: _parentPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(hint: '05XXXXXXXX'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppStrings.required;
                  if (v.trim().length < 9) return 'رقم الهاتف غير صحيح';
                  return null;
                },
              ),

              Gap(16.h),

              // Player phone (optional)
              _buildLabel('${AppStrings.playerPhone} (اختياري)'),
              Gap(6.h),
              TextFormField(
                controller: _playerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(hint: '05XXXXXXXX'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  if (v.trim().length < 7) return 'رقم الهاتف غير صحيح';
                  return null;
                },
              ),

              Gap(16.h),

              // Notes (optional)
              _buildLabel('${AppStrings.notes} (اختياري)'),
              Gap(6.h),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                maxLength: 500,
                decoration: _inputDecoration(hint: 'أدخل ملاحظات إضافية'),
              ),

              Gap(24.h),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        AppStrings.save,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),

              Gap(40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.grey700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14.sp),
      filled: true,
      fillColor: AppColors.white,
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: AppColors.grey400)
          : null,
      contentPadding:
          EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
