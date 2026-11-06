// Scrollable padded content area used under DesktopPageHeader inside
// DesktopShell/TabletShell — same padding/scroll behavior as the Dashboard
// reference content area.
import 'package:flutter/material.dart';

class DesktopContentContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DesktopContentContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: padding,
        child: child,
      ),
    );
  }
}
