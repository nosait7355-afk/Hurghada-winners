import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/router/app_router.dart';
import 'package:hurghada_winners/core/widgets/confirm_delete_dialog.dart';
import 'package:hurghada_winners/core/widgets/full_screen_image_viewer.dart';
import 'package:hurghada_winners/features/player/presentation/screens/player_detail_screen.dart';
import 'package:hurghada_winners/features/subscription/data/renewal_request_service.dart';
import 'package:hurghada_winners/features/subscription/presentation/screens/renew_subscription_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final renewalRequestsProvider = FutureProvider.autoDispose
    .family<List<RenewalRequest>, String>((ref, status) {
  return sl<RenewalRequestService>().list(status);
});

final pendingRenewalCountProvider = FutureProvider.autoDispose<int>((ref) {
  return sl<RenewalRequestService>().pendingCount();
});

/// أيقونة طلبات التجديد مع عدّاد المعلّق — للسوبر أدمن في الصفحة الرئيسية.
class RenewalRequestsBadgeIcon extends ConsumerWidget {
  final Color? color;
  const RenewalRequestsBadgeIcon({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingRenewalCountProvider).valueOrNull ?? 0;
    return IconButton(
      tooltip: 'طلبات التجديد',
      color: color,
      onPressed: () async {
        await context.push(AppRoutes.renewalRequests);
        ref.invalidate(pendingRenewalCountProvider);
      },
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: const Icon(Icons.receipt_long_outlined),
      ),
    );
  }
}

/// طلبات تجديد الاشتراك المرسلة من اللاعبين — قبول (بتسجيل التجديد) أو رفض.
class RenewalRequestsScreen extends ConsumerWidget {
  const RenewalRequestsScreen({super.key});

  static const _tabs = [
    ('pending', 'قيد المراجعة'),
    ('approved', 'مقبولة'),
    ('rejected', 'مرفوضة'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('طلبات التجديد'),
          centerTitle: true,
          bottom: TabBar(tabs: [for (final t in _tabs) Tab(text: t.$2)]),
        ),
        body: TabBarView(
          children: [for (final t in _tabs) _RequestsList(status: t.$1)],
        ),
      ),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  final String status;
  const _RequestsList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(renewalRequestsProvider(status));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(renewalRequestsProvider(status).future),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          const SizedBox(height: 120),
          const Center(child: Text('تعذّر تحميل الطلبات')),
          Center(
            child: TextButton(
              onPressed: () => ref.invalidate(renewalRequestsProvider(status)),
              child: const Text('إعادة المحاولة'),
            ),
          ),
        ]),
        data: (items) {
          if (items.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('لا توجد طلبات')),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _RequestCard(request: items[i]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final RenewalRequest request;
  const _RequestCard({required this.request});

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(renewalRequestsProvider);
    ref.invalidate(pendingRenewalCountProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDelete(context,
        title: 'حذف الطلب',
        message: 'حذف طلب تجديد "${request.playerName}" نهائياً؟');
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sl<RenewalRequestService>().delete(request.id);
      _refreshAll(ref);
      messenger.showSnackBar(const SnackBar(
          content: Text('تم حذف الطلب'), backgroundColor: AppColors.success));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('تعذّر حذف الطلب'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    // القبول = تسجيل اشتراك التجديد فعلاً أولاً، ثم اعتماد الطلب.
    final renewed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RenewSubscriptionScreen(
          playerId: request.playerId,
          academyId: request.academyId,
          playerName: request.playerName,
        ),
      ),
    );
    if (renewed != true) return;
    try {
      await sl<RenewalRequestService>().review(request.id, approve: true);
      _refreshAll(ref);
      messenger.showSnackBar(const SnackBar(
        content: Text('تم تجديد الاشتراك وقبول الطلب'),
        backgroundColor: AppColors.success,
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تم التجديد لكن تعذّر تحديث حالة الطلب'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض طلب التجديد'),
        content: TextField(
          controller: ctrl,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'سبب الرفض (يظهر للاعب)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('رفض', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null) return;
    try {
      await sl<RenewalRequestService>()
          .review(request.id, approve: false, rejectionReason: reason);
      _refreshAll(ref);
      messenger.showSnackBar(const SnackBar(
        content: Text('تم رفض الطلب'),
        backgroundColor: AppColors.success,
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('تعذّر رفض الطلب'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final date = DateFormat('dd/MM/yyyy – hh:mm a', 'ar').format(r.createdAt.toLocal());
    final hasImage = r.playerImageUrl != null && r.playerImageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PlayerDetailScreen(
                playerId: r.playerId,
                academyId: r.academyId,
              ),
            )),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage:
                      hasImage ? CachedNetworkImageProvider(r.playerImageUrl!) : null,
                  child: hasImage
                      ? null
                      : const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.playerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        [
                          if (r.academyName.isNotEmpty) 'الفرع: ${r.academyName}',
                          if (r.playerCode.isNotEmpty) 'كود: ${r.playerCode}',
                        ].join('  •  '),
                        style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                      ),
                      Text(date,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grey500)),
                    ],
                  ),
                ),
                DeleteIconButton(onPressed: () => _delete(context, ref)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: r.receiptUrl.isEmpty
                ? null
                : () => showFullScreenImage(context, r.receiptUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 180,
                width: double.infinity,
                color: AppColors.grey100,
                child: r.receiptUrl.isEmpty
                    ? const Icon(Icons.receipt_long_outlined,
                        color: AppColors.grey400)
                    : CachedNetworkImage(imageUrl: r.receiptUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('ملاحظة اللاعب: ${r.note}',
                style: const TextStyle(fontSize: 13, color: AppColors.grey700)),
          ],
          if (r.status == 'rejected' && r.rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('سبب الرفض: ${r.rejectionReason}',
                style: const TextStyle(fontSize: 13, color: AppColors.error)),
          ],
          if (r.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(context, ref),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('قبول وتجديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, ref),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
