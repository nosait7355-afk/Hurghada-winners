import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// A reusable multi-select chip field.
///
/// - [options] are the suggested values shown as chips.
/// - [selected] is the current selection.
/// - When [allowCustom] is true, a small input lets the user add a value that
///   is not in [options] (used for the extensible sports list).
class MultiSelectChips extends StatefulWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool allowCustom;
  final String? customHint;

  const MultiSelectChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.allowCustom = false,
    this.customHint,
  });

  @override
  State<MultiSelectChips> createState() => _MultiSelectChipsState();
}

class _MultiSelectChipsState extends State<MultiSelectChips> {
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggle(String value) {
    final next = List<String>.from(widget.selected);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    widget.onChanged(next);
  }

  void _addCustom() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    final next = List<String>.from(widget.selected);
    if (!next.contains(value)) next.add(value);
    _customController.clear();
    widget.onChanged(next);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Merge options with any selected custom values not present in options.
    final allChips = <String>[
      ...widget.options,
      ...widget.selected.where((s) => !widget.options.contains(s)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: allChips.map((option) {
            final isSelected = widget.selected.contains(option);
            return FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isSelected ? AppColors.white : AppColors.grey700,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _toggle(option),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.white,
              checkmarkColor: AppColors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.grey300,
              ),
            );
          }).toList(),
        ),
        if (widget.allowCustom) ...[
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustom(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.customHint ?? 'إضافة رياضة أخرى',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              Gap(8.w),
              IconButton.filled(
                onPressed: _addCustom,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
