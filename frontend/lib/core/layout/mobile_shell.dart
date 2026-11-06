// Mobile tier (<700px) — stays exactly as today: no shared chrome, each
// screen renders its own Scaffold/AppBar as it always has. This widget exists
// only so the three-tier architecture is explicit; it never changes output.
import 'package:flutter/material.dart';

class MobileShell extends StatelessWidget {
  final Widget child;

  const MobileShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
