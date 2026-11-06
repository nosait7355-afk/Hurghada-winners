// Adaptive grid for Desktop/Tablet cards — 3 or 4 columns on desktop
// depending on available width, 2 columns on tablet (caller passes the count
// chosen by the screen's own tier check, same convention as the Dashboard).
import 'package:flutter/material.dart';

class DesktopGrid extends StatelessWidget {
  final List<Widget> children;
  final int desktopColumns;
  final int tabletColumns;
  final double spacing;
  final double childAspectRatio;
  final bool isDesktop;

  const DesktopGrid({
    super.key,
    required this.children,
    required this.isDesktop,
    this.desktopColumns = 3,
    this.tabletColumns = 2,
    this.spacing = 16,
    this.childAspectRatio = 1.7,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = !isDesktop
          ? tabletColumns
          : constraints.maxWidth > 1600
              ? 4
              : desktopColumns;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: children.length,
        itemBuilder: (_, i) => children[i],
      );
    });
  }
}
