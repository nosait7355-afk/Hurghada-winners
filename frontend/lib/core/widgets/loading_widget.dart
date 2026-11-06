import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48.w,
            height: 48.w,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3.w,
            ),
          ),
          if (message != null) ...[
            Gap(16.h),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline small loader for buttons/actions
class InlineLoader extends StatelessWidget {
  final Color? color;
  final double size;

  const InlineLoader({super.key, this.color, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.toDouble(),
      height: size.toDouble(),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? AppColors.white,
      ),
    );
  }
}

/// Full-screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: AppColors.black.withValues(alpha: 0.4),
            child: LoadingWidget(message: message ?? AppStrings.loading),
          ),
      ],
    );
  }
}
