import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// The keyboard focus ring, drawn over the child's edge so nothing moves.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.on,
    required this.child,
    this.color = Tokens.ink,
    this.corners,
  });

  final bool on;
  final Color color;
  final BorderRadius? corners;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: corners,
        border: on ? Border.all(color: color, width: Tokens.focusRing) : null,
      ),
      child: child,
    );
  }
}
