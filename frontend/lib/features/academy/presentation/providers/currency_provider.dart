import 'package:hurghada_winners/core/utils/currency_utils.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves the currency CODE (EGP/SAR/KWD/USD) for a given academy id,
/// reading from the already-loaded academies list. Falls back to EGP.
///
/// For academy_admin the academies list contains only their own academy;
/// for super_admin it contains all academies — so this works for both.
final academyCurrencyCodeProvider =
    Provider.family<String, String?>((ref, academyId) {
  if (academyId == null) return CurrencyUtils.defaultCode;
  final academies = ref.watch(academiesProvider).valueOrNull;
  if (academies != null) {
    for (final a in academies) {
      if (a.id == academyId) return a.currency;
    }
  }
  return CurrencyUtils.defaultCode;
});

/// Convenience: the Arabic currency LABEL (e.g. 'جنيه') for an academy id.
final academyCurrencyLabelProvider =
    Provider.family<String, String?>((ref, academyId) {
  final code = ref.watch(academyCurrencyCodeProvider(academyId));
  return CurrencyUtils.label(code);
});
