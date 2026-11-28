import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// The raised panel look of menus and popovers.
class FloatingPanel extends StatelessWidget {
  const FloatingPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: Tokens.keyCorners,
        boxShadow: [
          BoxShadow(
            color: Tokens.shadow,
            blurRadius: Tokens.shadowBlur,
            offset: Offset(0, Tokens.shadowDrop),
          ),
        ],
      ),
      // the fill and the lit top edge are inside the corners, so a row's
      // hover mark stops at them
      child: ClipRRect(
        borderRadius: Tokens.keyCorners,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Tokens.edgeLight)),
          ),
          child: ColoredBox(color: Tokens.raised, child: child),
        ),
      ),
    );
  }
}
