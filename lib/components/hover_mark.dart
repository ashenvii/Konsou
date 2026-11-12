import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

class HoverMark extends StatelessWidget {
  const HoverMark({super.key, required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: on
          ? BoxDecoration(
              color: Tokens.mint.withValues(alpha: 0.06),
              border: const Border(
                bottom: BorderSide(color: Tokens.mint, width: Tokens.hoverEdge),
              ),
            )
          : const BoxDecoration(),
      child: child,
    );
  }
}
