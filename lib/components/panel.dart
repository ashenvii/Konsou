import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// A block on the surface color. Square, no border.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = Tokens.space4});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Tokens.surface,
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}
