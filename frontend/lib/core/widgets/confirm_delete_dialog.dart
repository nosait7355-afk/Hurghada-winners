import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// تأكيد حذف نهائي — يعيد true فقط عند الضغط على "حذف".
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text('$message\n\nلا يمكن التراجع عن الحذف.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  return ok == true;
}

/// زر حذف صغير موحّد لعناصر القوائم.
class DeleteIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double? size;
  const DeleteIconButton({super.key, required this.onPressed, this.size});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'حذف',
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.delete_outline, color: AppColors.error, size: size ?? 20),
      onPressed: onPressed,
    );
  }
}
