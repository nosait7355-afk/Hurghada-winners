// One-call wrapper: picks DesktopShell vs TabletShell and lays out the
// standard header+content structure. Screens just supply their content
// widget — this is the piece every Desktop-ready screen below uses.
import 'package:hurghada_winners/core/layout/desktop_content_container.dart';
import 'package:hurghada_winners/core/layout/desktop_page_header.dart';
import 'package:hurghada_winners/core/layout/desktop_shell.dart';
import 'package:hurghada_winners/core/layout/responsive.dart';
import 'package:hurghada_winners/core/layout/tablet_shell.dart';
import 'package:flutter/material.dart';

class DesktopScaffold extends StatelessWidget {
  final String location;
  final ScreenTier tier;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget content;
  final EdgeInsetsGeometry contentPadding;

  const DesktopScaffold({
    super.key,
    required this.location,
    required this.tier,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.content,
    this.contentPadding = const EdgeInsets.all(24),
  }) : assert(tier != ScreenTier.mobile,
            'DesktopScaffold is only for desktop/tablet tiers');

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        DesktopPageHeader(title: title, subtitle: subtitle, actions: actions),
        DesktopContentContainer(padding: contentPadding, child: content),
      ],
    );

    return tier == ScreenTier.desktop
        ? DesktopShell(location: location, child: body)
        : TabletShell(location: location, child: body);
  }
}
