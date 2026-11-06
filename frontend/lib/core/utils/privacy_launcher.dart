import 'package:hurghada_winners/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the official Privacy Policy URL ([AppConstants.privacyPolicyUrl])
/// in the device's default browser. Used everywhere a "سياسة الخصوصية" link
/// appears (login, sidebar/settings, app details) so the destination is
/// consistent and configurable from a single constant.
Future<void> openPrivacyPolicy(BuildContext context) async {
  final uri = Uri.parse(AppConstants.privacyPolicyUrl);
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذّر فتح الرابط')),
    );
  }
}
