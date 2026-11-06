import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/features/academy_album/data/academy_album_service.dart';
import 'package:hurghada_winners/features/academy_album/data/album_image.dart';
import 'package:hurghada_winners/features/academy_album/presentation/dialogs/album_form_dialog.dart';
import 'package:hurghada_winners/features/academy_album/presentation/providers/album_providers.dart';
import 'package:hurghada_winners/features/academy_album/presentation/screens/album_viewer_screen.dart';
import 'package:hurghada_winners/features/academy_album/presentation/widgets/album_grid.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/dashboard/presentation/providers/selected_academy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ألبوم الأكاديمية — جهة المدير: عرض + إضافة + تعديل + حذف.
class AcademyAlbumScreen extends ConsumerWidget {
  const AcademyAlbumScreen({super.key});

  AcademyAlbumService get _service => sl<AcademyAlbumService>();

  Future<void> _add(BuildContext context, WidgetRef ref, String? academyId) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<AlbumFormResult>(
      context: context,
      builder: (_) => const AlbumFormDialog(),
    );
    if (res == null || res.imagePath == null) return;
    try {
      await _service.upload(
        imagePath: res.imagePath!,
        title: res.title,
        description: res.description,
        academyId: academyId,
      );
      ref.read(academyAlbumProvider(academyId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تمت إضافة الصورة بنجاح'), backgroundColor: AppColors.success));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(albumErrorMessage(e, fallback: 'تعذّرت الإضافة. حاول مرة أخرى.')),
        backgroundColor: AppColors.error));
    }
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, AlbumImage img, String? academyId) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<AlbumFormResult>(
      context: context,
      builder: (_) => AlbumFormDialog(existing: img),
    );
    if (res == null) return;
    try {
      await _service.update(id: img.id, title: res.title, description: res.description);
      ref.read(academyAlbumProvider(academyId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم تحديث الصورة'), backgroundColor: AppColors.success));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(albumErrorMessage(e, fallback: 'تعذّر التحديث.')),
        backgroundColor: AppColors.error));
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, AlbumImage img, String? academyId) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل تريد حذف هذه الصورة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(img.id);
      ref.read(academyAlbumProvider(academyId).notifier).refresh();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم حذف الصورة'), backgroundColor: AppColors.success));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(albumErrorMessage(e, fallback: 'تعذّر الحذف.')),
        backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final academyId = ref.watch(effectiveAcademyIdProvider);

    // super_admin بلا أكاديمية مختارة: الخادم لا يعرف أي ألبوم يعرض، فنوضّح
    // السبب بدل رمي طلب يفشل بـ 400 ويظهر كخطأ عام.
    if (user?.isSuperAdmin == true && academyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ألبوم الأكاديمية')),
        body: const _AlbumNotice(
          icon: Icons.apartment_outlined,
          text: 'اختر أكاديمية من لوحة التحكم أولاً لعرض ألبومها',
        ),
      );
    }

    final state = ref.watch(academyAlbumProvider(academyId));
    final notifier = ref.read(academyAlbumProvider(academyId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('ألبوم الأكاديمية')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref, academyId),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('إضافة صورة'),
      ),
      body: _AlbumBody(
        state: state,
        onRetry: notifier.refresh,
        onRefresh: notifier.refresh,
        onLoadMore: notifier.loadMore,
        onTapImage: (i) => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AlbumViewerScreen(images: state.items, initialIndex: i),
        )),
        onEdit: (img) => _edit(context, ref, img, academyId),
        onDelete: (img) => _delete(context, ref, img, academyId),
      ),
    );
  }
}

/// رسالة الخطأ الحقيقية القادمة من الخادم إن وُجدت — تُغني عن رسالة عامة
/// تُخفي السبب (مثل "معرّف الأكاديمية مطلوب").
String albumErrorMessage(Object? error, {required String fallback}) {
  if (error is AppException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return fallback;
}

/// حالة إعلامية بسيطة (فراغ / تنبيه) بنفس تنسيق باقي حالات الشاشة.
class _AlbumNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AlbumNotice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48.sp, color: AppColors.grey500),
            SizedBox(height: 12.h),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey500, fontSize: 15.sp),
            ),
          ],
        ),
      ),
    );
  }
}

/// جسم مشترك بين شاشة المدير واللاعب — نفس حالات التحميل/الخطأ/الفراغ.
class _AlbumBody extends StatelessWidget {
  final AlbumState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(int) onTapImage;
  final void Function(AlbumImage)? onEdit;
  final void Function(AlbumImage)? onDelete;

  const _AlbumBody({
    required this.state,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onTapImage,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 44),
              SizedBox(height: 12.h),
              Text(
                albumErrorMessage(state.error, fallback: 'تعذّر تحميل الألبوم'),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return const _AlbumNotice(
        icon: Icons.photo_library_outlined,
        text: 'لا توجد صور بعد',
      );
    }
    return AlbumGrid(
      items: state.items,
      loadingMore: state.loadingMore,
      onLoadMore: onLoadMore,
      onRefresh: onRefresh,
      onTapImage: onTapImage,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

/// يُعاد تصديره ليستخدمه شاشة اللاعب دون تكرار.
class AlbumBody extends StatelessWidget {
  final AlbumState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(int) onTapImage;

  const AlbumBody({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onTapImage,
  });

  @override
  Widget build(BuildContext context) => _AlbumBody(
        state: state,
        onRetry: onRetry,
        onRefresh: onRefresh,
        onLoadMore: onLoadMore,
        onTapImage: onTapImage,
      );
}
