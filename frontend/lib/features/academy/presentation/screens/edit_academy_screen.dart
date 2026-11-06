import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/core/constants/sports_constants.dart';
import 'package:hurghada_winners/core/utils/currency_utils.dart';
import 'package:hurghada_winners/core/widgets/multi_select_chips.dart';
import 'package:hurghada_winners/features/academy/domain/entities/academy_entity.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class EditAcademyScreen extends ConsumerStatefulWidget {
  final AcademyEntity academy;

  const EditAcademyScreen({super.key, required this.academy});

  @override
  ConsumerState<EditAcademyScreen> createState() => _EditAcademyScreenState();
}

class _EditAcademyScreenState extends ConsumerState<EditAcademyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _facebookController;
  late final TextEditingController _tiktokController;
  late final TextEditingController _instagramController;

  late String _selectedCurrency;
  late List<String> _selectedSports;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.academy.name);
    _phoneController = TextEditingController(text: widget.academy.phone);
    _addressController = TextEditingController(text: widget.academy.address);
    _websiteController = TextEditingController(text: widget.academy.websiteUrl ?? '');
    _facebookController = TextEditingController(text: widget.academy.facebookUrl ?? '');
    _tiktokController = TextEditingController(text: widget.academy.tiktokUrl ?? '');
    _instagramController = TextEditingController(text: widget.academy.instagramUrl ?? '');
    _selectedCurrency = CurrencyUtils.codes.contains(widget.academy.currency)
        ? widget.academy.currency
        : CurrencyUtils.defaultCode;
    _selectedSports = widget.academy.sports.isNotEmpty
        ? List<String>.from(widget.academy.sports)
        : const [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.required;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.required;
    }
    if (value.trim().length < 7) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار رياضة واحدة على الأقل'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(academiesProvider.notifier).updateAcademy(
          id: widget.academy.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          currency: _selectedCurrency,
          sports: _selectedSports,
          websiteUrl: _websiteController.text.trim(),
          facebookUrl: _facebookController.text.trim(),
          tiktokUrl: _tiktokController.text.trim(),
          instagramUrl: _instagramController.text.trim(),
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
          content: Text('تم تحديث الفرع بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الفرع'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header — show logo or default icon
                Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: widget.academy.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: Image.network(
                              widget.academy.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.sports_tennis,
                                color: AppColors.primary,
                                size: 40.sp,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.sports_tennis,
                            color: AppColors.primary,
                            size: 40.sp,
                          ),
                  ),
                ),
                Gap(28.h),

                // Name field
                Text(
                  AppStrings.academyName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _nameController,
                  validator: _validateRequired,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'أدخل اسم الفرع',
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(20.h),

                // Phone field
                Text(
                  AppStrings.academyPhone,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _phoneController,
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'أدخل رقم الهاتف',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(20.h),

                // Address field
                Text(
                  AppStrings.academyAddress,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _addressController,
                  validator: _validateRequired,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'أدخل عنوان الفرع',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(20.h),

                // Currency field
                Text(
                  AppStrings.currencyField,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  items: CurrencyUtils.codes
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(CurrencyUtils.labelWithCode(c)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(
                      () => _selectedCurrency = val ?? CurrencyUtils.defaultCode),
                ),
                Gap(20.h),

                // Sports multi-select
                Text(
                  'الرياضات الموجودة بالفرع',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                MultiSelectChips(
                  options: SportsConstants.defaultSports,
                  selected: _selectedSports,
                  allowCustom: true,
                  customHint: 'إضافة رياضة أخرى',
                  onChanged: (sports) =>
                      setState(() => _selectedSports = sports),
                ),
                Gap(20.h),

                // Social media links (optional)
                Text(
                  'روابط التواصل الاجتماعي (اختياري)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'الموقع الإلكتروني',
                    prefixIcon: const Icon(Icons.language_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(12.h),
                TextFormField(
                  controller: _facebookController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'فيسبوك',
                    prefixIcon: const Icon(Icons.facebook_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(12.h),
                TextFormField(
                  controller: _tiktokController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'تيك توك',
                    prefixIcon: const Icon(Icons.music_note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(12.h),
                TextFormField(
                  controller: _instagramController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'إنستقرام',
                    prefixIcon: const Icon(Icons.camera_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                Gap(32.h),

                // Save button
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 52.h),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
                ),

                Gap(16.h),

                // Cancel button
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 52.h),
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey700,
                      side: const BorderSide(color: AppColors.grey300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
