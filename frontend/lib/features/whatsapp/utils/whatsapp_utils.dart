import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppUtils {
  WhatsAppUtils._();

  /// Cleans a phone number and builds a wa.me URL with an optional message.
  static String buildUrl(String phone, {String? message}) {
    // Strip everything except digits and leading +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Remove leading + for wa.me (it uses plain digits)
    String digits = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;

    // Normalize Egyptian local format: 01XXXXXXXXX → 201XXXXXXXXX
    if (RegExp(r'^0[0-9]{10}$').hasMatch(digits)) {
      digits = '2$digits'; // 0XXX → 20XXX
    }

    final base = 'https://wa.me/$digits';
    if (message == null || message.isEmpty) return base;
    final encoded = Uri.encodeComponent(message);
    return '$base?text=$encoded';
  }

  /// Builds a direct whatsapp:// scheme URI (most reliable on Android).
  /// Both WhatsApp and WhatsApp Business register this scheme.
  static String buildDirectUrl(String phone, {String? message}) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    String digits = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;
    if (RegExp(r'^0[0-9]{10}$').hasMatch(digits)) {
      digits = '2$digits';
    }
    if (message != null && message.isNotEmpty) {
      return 'whatsapp://send?phone=$digits&text=${Uri.encodeComponent(message)}';
    }
    return 'whatsapp://send?phone=$digits';
  }

  /// Opens WhatsApp. Returns false if it could not be opened.
  ///
  /// Strategy (Android 11+ compatible, no canLaunchUrl gate):
  /// 1. whatsapp:// direct scheme — works on WhatsApp & WhatsApp Business.
  /// 2. https://wa.me/ web URL with externalApplication mode.
  /// 3. https://wa.me/ with platformDefault (browser/chooser fallback).
  static Future<bool> open(String phone, {String? message}) async {
    // 1) Direct whatsapp:// scheme — most reliable on all Android versions.
    try {
      final directUri = Uri.parse(buildDirectUrl(phone, message: message));
      final ok = await launchUrl(directUri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    } catch (_) {}

    // 2) HTTPS wa.me deep link — lets Android resolve via App Links.
    final webUri = Uri.parse(buildUrl(phone, message: message));
    try {
      final ok = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    } catch (_) {}

    // 3) Platform default — opens browser or OS chooser as last resort.
    try {
      return await launchUrl(webUri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  /// الدعم الفني: واتساب على رقم الدعم برسالة جاهزة. يُظهر تنبيهاً إن تعذّر
  /// فتح واتساب.
  static Future<void> openSupport(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await open(
      AppConstants.supportWhatsappNumber,
      message: AppConstants.supportDefaultMessage,
    );
    if (!ok) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('تعذّر فتح واتساب')),
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // Message Templates
  // ──────────────────────────────────────────────────────────

  /// Simple contact greeting.
  static String contactTemplate({
    required String parentName,
    required String playerName,
    required String academyName,
  }) =>
      'السلام عليكم $parentName،\n'
      'أتواصل معك من $academyName بخصوص اللاعب $playerName.\n';

  /// تذكير تجديد الاشتراك — قالب واحد لكل الحالات (قبل الانتهاء / يوم
  /// الانتهاء / بعده). يحمل موعد التجديد بالتاريخ وطريقة الدفع.
  /// [endDate] تاريخ انتهاء آخر اشتراك (= موعد التجديد)، أو null إن لم يُعرف.
  static String renewalReminderTemplate({
    required String playerName,
    String? parentName,
    String academyName = 'أكاديمية Hurghada Winners',
    DateTime? endDate,
  }) {
    final greeting = (parentName == null || parentName.trim().isEmpty)
        ? 'السلام عليكم'
        : 'السلام عليكم ${parentName.trim()}';
    String status;
    if (endDate == null) {
      status = 'نود تذكيركم بتجديد اشتراك اللاعب $playerName في $academyName.';
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      final date = DateFormat('dd/MM/yyyy').format(end);
      final days = end.difference(today).inDays;
      if (days > 0) {
        final period = days == 1
            ? 'يوم واحد'
            : days == 2
                ? 'يومين'
                : days <= 10
                    ? '$days أيام'
                    : '$days يوماً';
        status = 'نود تذكيركم بأن اشتراك اللاعب $playerName في $academyName '
            'ينتهي بعد $period.\n'
            '📅 موعد التجديد: $date';
      } else if (days == 0) {
        status = 'نود تذكيركم بأن اشتراك اللاعب $playerName في $academyName '
            'ينتهي اليوم.\n'
            '📅 موعد التجديد: $date';
      } else {
        status = 'نود تذكيركم بأن اشتراك اللاعب $playerName في $academyName '
            'انتهى بتاريخ $date وفي انتظار التجديد.';
      }
    }
    return '$greeting\n\n'
        '$status\n\n'
        '💳 تقدر تدفع انستا باي أو فودافون كاش عن طريق '
        '${AppConstants.renewalPaymentNumber} مع إرسال سكرين التحويل.\n\n'
        'مع تحيات $academyName';
  }

  /// Share latest evaluation results with parent.
  static String evaluationFollowUpTemplate({
    required String parentName,
    required String playerName,
    required String average,
    required String grade,
    required String academyName,
  }) =>
      'السلام عليكم $parentName،\n'
      'نود مشاركتك نتائج آخر تقييم لابنك/ابنتك $playerName:\n'
      '📊 المتوسط: $average / 10\n'
      '🏆 التقدير: $grade\n'
      'نحرص دائماً على متابعة تطور اللاعبين لديكم.\n'
      'مع تحيات $academyName 🏀';

  /// غياب متكرر — سؤال ولي الأمر عن سبب الغياب.
  static String absenceTemplate({
    required String academyName,
    required String playerName,
    required int count,
  }) {
    final sessions = count == 2
        ? 'تمرينتين'
        : count <= 10
            ? '$count تمرينات'
            : '$count تمرينة';
    return 'السلام عليكم\n\n'
        'نلاحظ غياب اللاعب $playerName عن آخر $sessions متتالية في $academyName.\n'
        'ياريت تعرّفونا سبب الغياب، ونتمنى نشوفه في التمرينة الجاية.\n\n'
        'مع تحيات $academyName';
  }

  /// تهنئة عيد ميلاد اللاعب — نص ثابت كما طلبت الإدارة.
  static String birthdayTemplate({
    required String academyName,
    required String playerName,
  }) =>
      'السلام عليكم ورحمة الله وبركاته\n\n'
      'تتقدم إدارة $academyName بأصدق التهاني للاعب $playerName بمناسبة عيد ميلاده.\n\n'
      'نتمنى له دوام الصحة والتوفيق والنجاح الرياضي.\n\n'
      'كل عام وأنتم بخير.';

  /// طلب شراء منتج من متجر الأكاديمية — تُرسَل من اللاعب إلى واتساب المتجر.
  static String buyProductTemplate({
    required String academyName,
    required String productName,
    required String price,
    required String currency,
    String? playerName,
  }) =>
      'السلام عليكم،\n'
      'أرغب في شراء هذا المنتج من متجر $academyName:\n'
      '🛒 المنتج: $productName\n'
      '💰 السعر: $price $currency'
      '${playerName != null && playerName.isNotEmpty ? '\n👤 اللاعب: $playerName' : ''}';
}
