import 'package:hurghada_winners/core/auth/saved_accounts_store.dart';
import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// صف كروت الحسابات المحفوظة أعلى شاشة الدخول: الضغط يدخل مباشرة،
/// و✕ يحذف الحساب من الجهاز بعد التأكيد.
class SavedAccountsStrip extends StatelessWidget {
  final List<SavedAccount> accounts;
  final ValueChanged<SavedAccount> onSelect;
  final ValueChanged<SavedAccount> onDelete;
  final bool enabled;

  const SavedAccountsStrip({
    super.key,
    required this.accounts,
    required this.onSelect,
    required this.onDelete,
    this.enabled = true,
  });

  Future<void> _confirmDelete(BuildContext context, SavedAccount a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب المحفوظ'),
        content: Text(
            'هل تريد حذف حساب "${a.displayName.isNotEmpty ? a.displayName : a.username}" من هذا الجهاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) onDelete(a);
  }

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'الحسابات المحفوظة',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        Gap(10.h),
        SizedBox(
          height: 118.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length,
            separatorBuilder: (_, __) => Gap(10.w),
            itemBuilder: (_, i) => _AccountCard(
              account: accounts[i],
              enabled: enabled,
              onTap: () => onSelect(accounts[i]),
              onDelete: () => _confirmDelete(context, accounts[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final SavedAccount account;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.enabled,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = account.displayName.isNotEmpty ? account.displayName : account.username;
    final hasImage = account.imageUrl != null && account.imageUrl!.isNotEmpty;

    return SizedBox(
      width: 104.w,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: enabled ? onTap : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage:
                            hasImage ? CachedNetworkImageProvider(account.imageUrl!) : null,
                        child: hasImage
                            ? null
                            : Text(
                                name.characters.first.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      Gap(8.h),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 2,
            end: 2,
            child: IconButton(
              tooltip: 'حذف',
              visualDensity: VisualDensity.compact,
              iconSize: 16.sp,
              onPressed: onDelete,
              icon: const Icon(Icons.close, color: AppColors.grey500),
            ),
          ),
        ],
      ),
    );
  }
}
