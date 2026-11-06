import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/core/errors/exceptions.dart';
import 'package:hurghada_winners/features/player_portal/data/player_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// ورقة "مشاركة صفحتي" من حساب اللاعب: رابط صفحته العامة (عرض فقط —
/// بلا اشتراكات أو أرقام تواصل) مع نسخ ومشاركة.
Future<void> showMySharePageSheet(BuildContext context, {String? playerName}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MyShareSheet(playerName: playerName ?? ''),
  );
}

class _MyShareSheet extends StatefulWidget {
  final String playerName;
  const _MyShareSheet({required this.playerName});

  @override
  State<_MyShareSheet> createState() => _MyShareSheetState();
}

class _MyShareSheetState extends State<_MyShareSheet> {
  String? _link;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final link = await sl<PlayerApiService>().myShareLink();
      if (mounted) setState(() => _link = link);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is AppException ? e.message : 'تعذّر تجهيز رابط الصفحة');
      }
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _link!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('تم نسخ الرابط'),
      backgroundColor: AppColors.success,
    ));
  }

  Future<void> _share() async {
    final name = widget.playerName.trim();
    await Share.share(
        '${name.isNotEmpty ? 'صفحة اللاعب $name' : 'صفحتي في الأكاديمية'}\n$_link');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('مشاركة صفحتي',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'رابط لصفحتك العامة يقدر أي حد يفتحه — بيعرض اسمك وصورتك وفيديوهاتك فقط.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.grey600),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error)),
              TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ] else if (_link == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(_link!,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 12.5)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('نسخ الرابط'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('مشاركة'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
