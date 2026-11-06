import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/team_kit/data/kit_booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// نتيجة مراجعة الحجز: الحقول (قد تكون معدّلة)، حالة الدفع والمبلغ، وحالة
/// المراجعة (approved/rejected) أو null إن كان المدير يحفظ التعديلات فقط
/// دون البتّ في الحجز بعد.
class BookingReviewResult {
  final String size;
  final String paymentStatus;
  final double paidAmount;
  final String? status; // approved | rejected | null (حفظ بدون قرار)
  const BookingReviewResult({
    required this.size,
    required this.paymentStatus,
    required this.paidAmount,
    this.status,
  });
}

/// حوار مراجعة حجز طقم فريق: المدير يعدّل المقاس، يحدّد حالة الدفع والمبلغ،
/// ثم يوافق أو يرفض الحجز.
class BookingReviewDialog extends StatefulWidget {
  final KitBooking booking;
  final List<String> availableSizes;
  const BookingReviewDialog({super.key, required this.booking, required this.availableSizes});

  @override
  State<BookingReviewDialog> createState() => _BookingReviewDialogState();
}

class _BookingReviewDialogState extends State<BookingReviewDialog> {
  late final TextEditingController _paidAmountCtrl;
  late String _size;
  late String _paymentStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    _paidAmountCtrl = TextEditingController(
      text: b.paidAmount == 0 ? '' : b.paidAmount.toString(),
    );
    _size = widget.availableSizes.contains(b.size)
        ? b.size
        : (widget.availableSizes.isNotEmpty ? widget.availableSizes.first : b.size);
    _paymentStatus = b.paymentStatus;
  }

  @override
  void dispose() {
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  BookingReviewResult? _buildResult({String? decision}) {
    final paidAmount = _paidAmountCtrl.text.trim().isEmpty
        ? 0.0
        : double.tryParse(_paidAmountCtrl.text.trim());
    if (paidAmount == null || paidAmount < 0) {
      setState(() => _error = 'أدخل مبلغاً صحيحاً');
      return null;
    }
    // الموافقة = الإيصال مقبول، فالحجز مدفوع (الخادم يفرض نفس القاعدة).
    final approving = decision == 'approved';
    return BookingReviewResult(
      size: _size,
      paymentStatus: approving ? 'paid' : _paymentStatus,
      paidAmount:
          approving && paidAmount == 0 ? widget.booking.price : paidAmount,
      status: decision,
    );
  }

  void _submit(String? decision) {
    final result = _buildResult(decision: decision);
    if (result == null) return;
    Navigator.pop(context, result);
  }

  /// عرض الإيصال بحجم كامل مع تكبير — نفس تجربة إيصال طلب الانضمام.
  void _zoomReceipt(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// الإيصال أعلى الحوار: المدير يراه قبل أن يقرّر الموافقة أو الرفض.
  Widget _receiptSection() {
    final url = widget.booking.receiptUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text('إيصال الدفع', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        if (widget.booking.hasReceipt)
          GestureDetector(
            onTap: () => _zoomReceipt(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 170,
                        color: AppColors.grey100,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  height: 170,
                  color: AppColors.grey100,
                  child: const Center(child: Text('تعذّر تحميل صورة الإيصال')),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'لا توجد صورة إيصال لهذا الحجز',
              style: TextStyle(color: AppColors.grey500),
            ),
          ),
        if (widget.booking.hasReceipt)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('اضغط على الصورة لتكبيرها',
                style: TextStyle(fontSize: 11, color: AppColors.grey500)),
          ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return AlertDialog(
      title: Text('مراجعة حجز: ${b.playerName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _receiptSection(),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('المقاس', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.availableSizes.map((s) {
                final selected = _size == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        if (b.status == 'pending_review') ...[
          TextButton(
            onPressed: () => _submit('rejected'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
          ElevatedButton(
            onPressed: () => _submit('approved'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('موافقة'),
          ),
        ] else
          ElevatedButton(
            onPressed: () => _submit(null),
            child: const Text('حفظ'),
          ),
      ],
    );
  }
}
