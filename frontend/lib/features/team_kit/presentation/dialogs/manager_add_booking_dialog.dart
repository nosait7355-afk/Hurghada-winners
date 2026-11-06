import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/player/domain/entities/player_entity.dart';
import 'package:hurghada_winners/features/player/presentation/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// نتيجة إضافة حجز من حساب المدير.
class ManagerBookingResult {
  final String playerId;
  final String size;
  final String paymentStatus;
  final double paidAmount;
  const ManagerBookingResult({
    required this.playerId,
    required this.size,
    required this.paymentStatus,
    required this.paidAmount,
  });
}

/// حوار يضيف من خلاله المدير حجز طقم فريق للاعب مباشرة: بحث عن اللاعب ثم
/// نفس بيانات الحجز (المقاس/حالة الدفع).
class ManagerAddBookingDialog extends ConsumerStatefulWidget {
  final List<String> availableSizes;
  const ManagerAddBookingDialog({super.key, required this.availableSizes});

  @override
  ConsumerState<ManagerAddBookingDialog> createState() =>
      _ManagerAddBookingDialogState();
}

class _ManagerAddBookingDialogState extends ConsumerState<ManagerAddBookingDialog> {
  final _searchCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController();
  PlayerEntity? _selectedPlayer;
  String? _size;
  String _paymentStatus = 'unpaid';
  String? _error;

  @override
  void initState() {
    super.initState();
    _size = widget.availableSizes.isNotEmpty ? widget.availableSizes.first : null;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedPlayer == null) {
      setState(() => _error = 'اختر اللاعب أولاً');
      return;
    }
    if (_size == null) {
      setState(() => _error = 'اختر مقاساً');
      return;
    }
    final paidAmount = _paidAmountCtrl.text.trim().isEmpty
        ? 0.0
        : double.tryParse(_paidAmountCtrl.text.trim());
    if (paidAmount == null || paidAmount < 0) {
      setState(() => _error = 'أدخل مبلغاً صحيحاً');
      return;
    }
    Navigator.pop(
      context,
      ManagerBookingResult(
        playerId: _selectedPlayer!.id,
        size: _size!,
        paymentStatus: _paymentStatus,
        paidAmount: paidAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(playerSearchProvider);

    return AlertDialog(
      title: const Text('إضافة حجز طقم فريق'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedPlayer == null) ...[
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'ابحث عن لاعب بالاسم',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (q) =>
                    ref.read(playerSearchProvider.notifier).search(q),
              ),
              const SizedBox(height: 8),
              searchResults.when(
                data: (players) => players.isEmpty
                    ? const SizedBox.shrink()
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: players.length,
                          itemBuilder: (_, i) {
                            final p = players[i];
                            return ListTile(
                              dense: true,
                              title: Text(p.fullName),
                              onTap: () => setState(() {
                                _selectedPlayer = p;
                                _error = null;
                              }),
                            );
                          },
                        ),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ] else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person, color: AppColors.primary),
                title: Text(_selectedPlayer!.fullName),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedPlayer = null),
                ),
              ),
            const SizedBox(height: 8),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('المقاس', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.availableSizes.map((s) {
                return ChoiceChip(
                  label: Text(s),
                  selected: _size == s,
                  onSelected: (_) => setState(() => _size = s),
                  selectedColor: AppColors.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('حالة الدفع', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('لم يدفع بعد'),
                    selected: _paymentStatus == 'unpaid',
                    onSelected: (_) => setState(() => _paymentStatus = 'unpaid'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('مدفوع'),
                    selected: _paymentStatus == 'paid',
                    selectedColor: AppColors.success.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _paymentStatus = 'paid'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _paidAmountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(labelText: 'المبلغ المدفوع (اختياري)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _submit, child: const Text('إضافة')),
      ],
    );
  }
}
