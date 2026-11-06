import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/features/academy_album/presentation/providers/album_providers.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:hurghada_winners/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:hurghada_winners/features/player_videos/presentation/providers/player_video_providers.dart';
import 'package:hurghada_winners/features/store/presentation/providers/store_providers.dart';
import 'package:hurghada_winners/features/team_kit/presentation/providers/team_kit_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hurghada_winners/features/offers/presentation/providers/offers_providers.dart';

/// زر تبديل الحساب في شريط لوحة اللاعب — يظهر فقط إن كان الحساب ضمن عائلة.
class SwitchAccountButton extends ConsumerWidget {
  const SwitchAccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(playerFamilyProvider).valueOrNull ?? const [];
    if (members.isEmpty) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'تبديل الحساب',
      icon: const Icon(Icons.switch_account_outlined),
      onPressed: () => showSwitchAccountSheet(context, members),
    );
  }
}

Future<void> showSwitchAccountSheet(
  BuildContext context,
  List<Map<String, dynamic>> members,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SwitchAccountSheet(members: members),
  );
}

class _SwitchAccountSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> members;
  const _SwitchAccountSheet({required this.members});

  @override
  ConsumerState<_SwitchAccountSheet> createState() => _SwitchAccountSheetState();
}

class _SwitchAccountSheetState extends ConsumerState<_SwitchAccountSheet> {
  String? _switchingId;

  String _errorText(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final msg = (e.response!.data as Map)['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    if (e is AppException) return e.message;
    return 'تعذّر التبديل إلى هذا الحساب';
  }

  Future<void> _switch(Map<String, dynamic> m) async {
    final accountId = m['accountId'] as String;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _switchingId = accountId);
    try {
      await ref.read(playerSessionProvider.notifier).switchTo(accountId);
      // كل بيانات البوابة تخص الحساب السابق — نُسقطها لتُجلب للحساب الجديد
      // (بما فيها الاسم والصورة أعلى اللوحة).
      ref
        ..invalidate(playerDashboardProvider)
        ..invalidate(playerNotificationsProvider)
        ..invalidate(playerFamilyProvider)
        ..invalidate(myVideosProvider)
        ..invalidate(playerStoreProvider)
        ..invalidate(playerKitProvider)
        ..invalidate(playerAlbumProvider)
        ..invalidate(playerOffersProvider);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('تم التبديل إلى ${m['fullName'] ?? ''}'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _switchingId = null);
      messenger.showSnackBar(
        SnackBar(content: Text(_errorText(e)), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _switchingId != null;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('تبديل الحساب',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('اختر الحساب الذي تريد فتحه',
                style: TextStyle(fontSize: 12, color: AppColors.grey600)),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final m in widget.members)
                  _memberTile(m, busy),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _memberTile(Map<String, dynamic> m, bool busy) {
    final image = m['image_url'] as String?;
    final hasImage = image != null && image.isNotEmpty;
    final isThis = _switchingId == m['accountId'];
    return ListTile(
      enabled: !busy,
      onTap: () => _switch(m),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primaryContainer,
        backgroundImage: hasImage ? CachedNetworkImageProvider(image) : null,
        child: hasImage ? null : const Icon(Icons.person, color: AppColors.primary),
      ),
      title: Text(m['fullName'] as String? ?? '',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        [
          if ((m['academyName'] as String? ?? '').isNotEmpty) m['academyName'],
          if ((m['playerCode'] as String? ?? '').isNotEmpty) m['playerCode'],
        ].join('  •  '),
      ),
      trailing: isThis
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chevron_left),
    );
  }
}
