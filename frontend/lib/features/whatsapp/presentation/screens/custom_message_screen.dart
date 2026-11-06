import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class CustomMessageScreen extends StatefulWidget {
  final String phone;
  final String parentName;
  final String playerName;

  const CustomMessageScreen({
    super.key,
    required this.phone,
    required this.parentName,
    required this.playerName,
  });

  @override
  State<CustomMessageScreen> createState() => _CustomMessageScreenState();
}

class _CustomMessageScreenState extends State<CustomMessageScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;

    setState(() => _sending = true);
    final opened = await WhatsAppUtils.open(widget.phone, message: msg);
    if (!mounted) return;
    setState(() => _sending = false);

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.whatsappNotInstalled),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.customMessage),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipient chip
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: AppColors.success, size: 20.sp),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      '${widget.parentName} (${widget.playerName})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.phone_outlined, color: AppColors.success, size: 18.sp),
                  Gap(4.w),
                  Text(
                    widget.phone,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
            Gap(16.h),

            // Message field
            Expanded(
              child: TextFormField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: AppStrings.writeMessageHere,
                  hintStyle: const TextStyle(color: AppColors.grey400),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppColors.success, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.all(16.r),
                ),
              ),
            ),
            Gap(16.h),

            // Send button
            ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp green
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              icon: _sending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Icon(Icons.send, size: 20.sp),
              label: Text(
                AppStrings.sendViaWhatsApp,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
