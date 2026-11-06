import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:hurghada_winners/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';

/// حوار موحّد لحالات حظر منصة Nosait:
/// - انتهاء/تعليق الاشتراك (SUBSCRIPTION_EXPIRED)
/// - تجاوز الحد الأقصى للاعبين (PLAYER_LIMIT_REACHED)
/// يحتوي زر "تواصل عبر واتساب" يفتح رقم إدارة Nosait برسالة جاهزة.
class PlatformBlockedDialog {
  PlatformBlockedDialog._();

  static bool _isShowing = false;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (_isShowing) return; // منع تكرار الحوار عند تعدّد الطلبات الفاشلة.
    _isShowing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(message, style: const TextStyle(height: 1.6)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await WhatsAppUtils.open(
                  AppConstants.companyWhatsappNumber,
                  message: AppConstants.contactDefaultMessage,
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('تواصل عبر واتساب'),
            ),
          ],
        ),
      );
    } finally {
      _isShowing = false;
    }
  }
}
