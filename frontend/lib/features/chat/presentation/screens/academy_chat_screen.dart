import 'dart:async';

import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/chat/data/chat_api_service.dart';
import 'package:hurghada_winners/features/chat/presentation/widgets/chat_view.dart';
import 'package:flutter/material.dart';

/// محادثة الأكاديمية مع لاعب محدّد (نص فقط). Polling كل 5 ثوانٍ.
class AcademyChatScreen extends StatefulWidget {
  final String playerId;
  final String playerName;
  const AcademyChatScreen({super.key, required this.playerId, required this.playerName});

  @override
  State<AcademyChatScreen> createState() => _AcademyChatScreenState();
}

class _AcademyChatScreenState extends State<AcademyChatScreen> {
  final _service = sl<ChatApiService>();
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    try {
      final data = await _service.getMessages(widget.playerId);
      final msgs = (data['messages'] as List<dynamic>).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _messages = msgs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && initial) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await _service.sendMessage(widget.playerId, text);
      _controller.clear();
      if (mounted) setState(() => _messages = [..._messages, msg]);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر إرسال الرسالة'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playerName.isEmpty ? 'محادثة' : widget.playerName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ChatView(
              messages: _messages,
              mySide: 'academy',
              controller: _controller,
              sending: _sending,
              onSend: _send,
            ),
    );
  }
}
