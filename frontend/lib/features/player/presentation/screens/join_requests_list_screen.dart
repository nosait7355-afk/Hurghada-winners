import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/player/data/join_request_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// مفتاح الاستعلام: الأكاديمية + حالة الطلب ('pending' أو 'rejected').
typedef _RequestsKey = ({String academyId, String status});

final _joinRequestsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, _RequestsKey>((ref, key) async {
  return sl<JoinRequestService>().list(
    academyId: key.academyId,
    status: key.status,
  );
});

/// قائمة طلبات الانضمام لأكاديمية (فرع) معيّنة — يظهر للأدمن الكامل
/// والمشرف على حدٍّ سواء (نفس صلاحية الوصول لصفحة اللاعبين).
///
/// تبويبان: "معلّقة" للطلبات التي تنتظر المراجعة، و"مرفوضة" لأرشيف الطلبات
/// المرفوضة — يمكن تعديل بياناتها والموافقة عليها لاحقاً من شاشة التفاصيل.
class JoinRequestsListScreen extends ConsumerWidget {
  final String academyId;
  const JoinRequestsListScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('طلبات الانضمام'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'معلّقة'),
              Tab(text: 'مرفوضة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestsTab(academyId: academyId, status: 'pending'),
            _RequestsTab(academyId: academyId, status: 'rejected'),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  final String academyId;
  final String status;
  const _RequestsTab({required this.academyId, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (academyId: academyId, status: status);
    final requestsAsync = ref.watch(_joinRequestsProvider(key));
    final isRejected = status == 'rejected';
    // الحذف النهائي للمدير الكامل والسوبر أدمن — لا للمشرف المحدود (الخادم يفرضه).
    final canDelete = (isRejected || status == 'pending') &&
        ref.watch(authStateProvider).valueOrNull?.user?.isAdmin != true;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_joinRequestsProvider(key)),
      child: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(40.r),
              child: const Center(
                child: Text('تعذّر تحميل الطلبات', style: TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return ListView(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 80.h),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 56.sp, color: AppColors.grey300),
                      Gap(12.h),
                      Text(
                        isRejected
                            ? 'لا توجد طلبات مرفوضة'
                            : 'لا توجد طلبات انضمام حالياً',
                        style: TextStyle(color: AppColors.grey500, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(16.r),
            itemCount: requests.length,
            separatorBuilder: (_, __) => Gap(10.h),
            itemBuilder: (context, index) {
              final r = requests[index];
              final createdAt = DateTime.tryParse(r['created_at'] as String? ?? '');
              final reason = r['rejectionReason'] as String?;
              return Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: () async {
                    await context.push(
                      AppRoutes.joinRequestDetail
                          .replaceFirst(':id', academyId)
                          .replaceFirst(':requestId', r['_id'] as String),
                    );
                    ref.invalidate(_joinRequestsProvider(key));
                  },
                  child: Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22.r,
                          backgroundColor: AppColors.primaryContainer,
                          backgroundImage: r['image_url'] != null
                              ? NetworkImage(r['image_url'] as String)
                              : null,
                          child: r['image_url'] == null
                              ? const Icon(Icons.person_outline, color: AppColors.primary)
                              : null,
                        ),
                        Gap(12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['fullName'] as String? ?? '',
                                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                              ),
                              Gap(4.h),
                              Text(
                                '${r['branch'] ?? ''} · ${r['parentPhone'] ?? ''}',
                                style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey600),
                              ),
                              if (createdAt != null) ...[
                                Gap(2.h),
                                Text(
                                  DateFormat('dd/MM/yyyy', 'ar').format(createdAt),
                                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey400),
                                ),
                              ],
                              if (isRejected && reason != null && reason.isNotEmpty) ...[
                                Gap(4.h),
                                Text(
                                  'سبب الرفض: $reason',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.error),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (canDelete)
                          IconButton(
                            tooltip: 'حذف نهائي',
                            icon: const Icon(Icons.delete_forever_outlined,
                                color: AppColors.error),
                            onPressed: () => _confirmDelete(context, ref, r, key),
                          )
                        else
                          const Icon(Icons.chevron_left, color: AppColors.grey400),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      Map<String, dynamic> r, _RequestsKey key) async {
    final name = r['fullName'] as String? ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف نهائي'),
        content: Text(
          'سيتم حذف طلب "$name" نهائياً مع حساب الدخول والصور، ولن يظهر مرة أخرى في أي مكان.\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await sl<JoinRequestService>().deleteRejected(r['_id'] as String);
      ref.invalidate(_joinRequestsProvider(key));
      messenger.showSnackBar(const SnackBar(
        content: Text('تم حذف الطلب نهائياً'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e is AppException ? e.message : 'تعذّر حذف الطلب'),
        backgroundColor: AppColors.error,
      ));
    }
  }
}
