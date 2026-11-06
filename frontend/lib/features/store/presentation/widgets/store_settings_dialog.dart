import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/core/constants/arab_countries.dart';
import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/store/data/store_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// نافذة إعدادات المتجر — ضبط رقم واتساب الذي تصل إليه طلبات الشراء، مع اختيار
/// كود الدولة (كل الدول العربية) فيُضاف تلقائياً للرقم المحلي عند الحفظ.
/// إن تُرك فارغاً تُرسَل الطلبات إلى رقم هاتف الأكاديمية الأساسي (fallback).
class StoreSettingsDialog extends StatefulWidget {
  final String? academyId;
  const StoreSettingsDialog({super.key, this.academyId});

  @override
  State<StoreSettingsDialog> createState() => _StoreSettingsDialogState();
}

class _StoreSettingsDialogState extends State<StoreSettingsDialog> {
  final _ctrl = TextEditingController();
  StoreService get _service => sl<StoreService>();

  ArabCountry _country = arabCountryDefault;
  bool _loading = true;
  bool _saving = false;
  String _phoneHint = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await _service.getSettings(academyId: widget.academyId);
      final split = splitStoredNumber(s.storeWhatsApp);
      setState(() {
        _country = split.country;
        _ctrl.text = split.local;
        _phoneHint = s.phone;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'تعذّر تحميل الإعدادات';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // يُبنى الرقم دولياً: كود الدولة + الرقم المحلي (بدون صفر البداية).
      final full = buildInternationalNumber(_country, _ctrl.text);
      await _service.updateStoreWhatsApp(full, academyId: widget.academyId);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() {
        _error = 'تعذّر الحفظ. حاول مجدداً.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = buildInternationalNumber(_country, _ctrl.text);
    return AlertDialog(
      title: const Text('إعدادات المتجر'),
      content: _loading
          ? const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'رقم واتساب المتجر — تصل إليه طلبات الشراء من اللاعبين.\n'
                  'اختر الدولة ثم اكتب الرقم المحلي؛ يُضاف كود الدولة تلقائياً.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey600),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CountryDropdown(
                      value: _country,
                      onChanged: (c) => setState(() => _country = c),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          LengthLimitingTextInputFormatter(15),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'الرقم المحلي',
                          hintText: 'مثال: 1001234567',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.chat, color: AppColors.success, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        preview.isEmpty
                            ? (_phoneHint.isNotEmpty
                                ? 'بدون رقم مخصص — سيُستخدم: $_phoneHint'
                                : 'اكتب الرقم لعرض المعاينة')
                            : 'الرقم النهائي: $preview',
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.grey700,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: (_loading || _saving) ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

/// قائمة منسدلة لاختيار الدولة — تعرض العلم + الكود مختصراً، وكل الدول العربية
/// داخل القائمة بأسمائها.
class _CountryDropdown extends StatelessWidget {
  final ArabCountry value;
  final ValueChanged<ArabCountry> onChanged;
  const _CountryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ArabCountry>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          selectedItemBuilder: (_) => arabCountries
              .map((c) => Align(
                    alignment: Alignment.center,
                    child: Text(c.shortLabel,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ))
              .toList(),
          items: arabCountries
              .map((c) => DropdownMenuItem<ArabCountry>(
                    value: c,
                    child: Text(c.fullLabel, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: (c) {
            if (c != null) onChanged(c);
          },
        ),
      ),
    );
  }
}
