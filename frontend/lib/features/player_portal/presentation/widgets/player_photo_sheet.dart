import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/widgets/full_screen_image_viewer.dart';
import 'package:hurghada_winners/features/player_portal/data/player_api_service.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

/// ورقة خيارات صورة اللاعب: عرضها، أو تغييرها (من المعرض أو الكاميرا)، أو حذفها.
Future<void> showPlayerPhotoSheet(
  BuildContext context,
  WidgetRef ref, {
  required bool hasImage,
  String? imageUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap(12.h),
          Container(
            width: 42.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Gap(8.h),
          if (hasImage && imageUrl != null)
            ListTile(
              leading: const Icon(Icons.zoom_out_map, color: AppColors.primary),
              title: const Text('عرض الصورة'),
              onTap: () {
                Navigator.pop(sheetContext);
                showFullScreenImage(context, imageUrl);
              },
            ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('اختيار صورة من المعرض'),
            onTap: () async {
              Navigator.pop(sheetContext);
              await _changePhoto(context, ref, ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            title: const Text('التقاط صورة بالكاميرا'),
            onTap: () async {
              Navigator.pop(sheetContext);
              await _changePhoto(context, ref, ImageSource.camera);
            },
          ),
          ListTile(
            enabled: hasImage,
            leading: Icon(
              Icons.delete_outline,
              color: hasImage ? AppColors.error : AppColors.grey200,
            ),
            title: Text(
              'حذف الصورة',
              style: TextStyle(color: hasImage ? AppColors.error : null),
            ),
            onTap: hasImage
                ? () async {
                    Navigator.pop(sheetContext);
                    await _deletePhoto(context, ref);
                  }
                : null,
          ),
          Gap(8.h),
        ],
      ),
    ),
  );
}

// الـ messenger يُلتقط قبل أي await حتى لا نستخدم BuildContext بعد فجوة async.
void _toast(ScaffoldMessengerState messenger, String message, {bool error = false}) {
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ),
  );
}

Future<void> _changePhoto(
    BuildContext context, WidgetRef ref, ImageSource source) async {
  final messenger = ScaffoldMessenger.of(context);

  // الكاميرا تُصغَّر عند الالتقاط حتى لا تتجاوز حد الحجم (2MB) في الخادم.
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 85,
  );
  if (picked == null) return;

  // الصور الأكبر من 2MB تُصغَّر تلقائياً عند الرفع (buildImageMultipart).
  try {
    await sl<PlayerApiService>().updatePhoto(picked.path);
    ref.invalidate(playerDashboardProvider);
    _toast(messenger, 'تم تحديث الصورة بنجاح');
  } catch (e) {
    _toast(messenger, 'تعذّر رفع الصورة. حاول مرة أخرى.', error: true);
  }
}

Future<void> _deletePhoto(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف الصورة'),
      content: const Text('هل تريد حذف صورتك الشخصية؟ ستعود الصورة الافتراضية.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('حذف', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await sl<PlayerApiService>().deletePhoto();
    ref.invalidate(playerDashboardProvider);
    _toast(messenger, 'تم حذف الصورة بنجاح');
  } catch (e) {
    _toast(messenger, 'تعذّر حذف الصورة. حاول مرة أخرى.', error: true);
  }
}
