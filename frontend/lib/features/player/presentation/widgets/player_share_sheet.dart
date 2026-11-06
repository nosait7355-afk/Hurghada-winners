import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/player/data/player_share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// ورقة مشاركة بروفايل اللاعب: نبذة عامة + رابط عرض فقط (نسخ/مشاركة/
/// إصدار رابط جديد/إيقاف).
Future<void> showPlayerShareSheet(
  BuildContext context, {
  required String playerId,
  required String playerName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PlayerShareSheet(playerId: playerId, playerName: playerName),
  );
}

class _PlayerShareSheet extends StatefulWidget {
  final String playerId;
  final String playerName;
  const _PlayerShareSheet({required this.playerId, required this.playerName});

  @override
  State<_PlayerShareSheet> createState() => _PlayerShareSheetState();
}

class _PlayerShareSheetState extends State<_PlayerShareSheet> {
  final _bioCtrl = TextEditingController();
  PlayerShareInfo? _info;
  bool _busy = true;
  String? _error;

  PlayerShareService get _service => sl<PlayerShareService>();

  @override
  void initState() {
    super.initState();
    _run(() => _service.enable(widget.playerId), loadBio: true);
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<PlayerShareInfo> Function() action,
      {bool loadBio = false, String? success}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await action();
      if (!mounted) return;
      setState(() {
        _info = info;
        if (loadBio) _bioCtrl.text = info.bio;
        _busy = false;
      });
      if (success != null) _toast(success);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'تعذّر تنفيذ العملية. حاول مرة أخرى.';
      });
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));

  Future<void> _copy() async {
    final link = _info?.link;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) _toast('تم نسخ الرابط');
  }

  Future<void> _share() async {
    final link = _info?.link;
    if (link == null) return;
    await Share.share('بروفايل اللاعب ${widget.playerName}\n$link');
  }

  Future<void> _confirmRegenerate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إصدار رابط جديد'),
        content: const Text('الرابط القديم سيتوقف عن العمل لكل من أُرسل إليه. متابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('متابعة')),
        ],
      ),
    );
    if (ok == true) {
      _run(() => _service.enable(widget.playerId, regenerate: true),
          success: 'تم إصدار رابط جديد');
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 12),
            Text('مشاركة بروفايل ${widget.playerName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'صفحة عرض فقط: الصورة والاسم والنبذة وسنة الميلاد والفرع والرياضة والفيديوهات — بدون اشتراكات أو تقييمات أو أرقام تواصل.',
              style: TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioCtrl,
              maxLength: 1000,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'نبذة عن اللاعب (تظهر في الصفحة)',
                border: OutlineInputBorder(),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          () => _service.updateBio(widget.playerId, _bioCtrl.text.trim()),
                          success: 'تم حفظ النبذة',
                        ),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('حفظ النبذة'),
              ),
            ),
            const Divider(height: 24),
            if (_busy && info == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (info != null && info.isEnabled) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  info.link!,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _copy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('نسخ الرابط'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _share,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('مشاركة'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _busy ? null : _confirmRegenerate,
                    icon: const Icon(Icons.autorenew, size: 18),
                    label: const Text('رابط جديد'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() => _service.disable(widget.playerId),
                            success: 'تم إيقاف الرابط'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    icon: const Icon(Icons.link_off, size: 18),
                    label: const Text('إيقاف الرابط'),
                  ),
                ],
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _busy ? null : () => _run(() => _service.enable(widget.playerId)),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('تفعيل رابط المشاركة'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
