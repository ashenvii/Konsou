import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'hover_mark.dart';

/// A raised console key: a face over a slab, a soft shadow under it and small
/// corners. Every button, the view switch and the sort are drawn on one.
/// [sunk] pushes it down most of the way (pressed, or the selected view).
/// [lit] is the app's live edge on hover.
class RaisedKey extends StatelessWidget {
  const RaisedKey({
    super.key,
    required this.child,
    this.primary = false,
    this.sunk = false,
    this.lit = false,
  });

  final Widget child;

  /// The main action: a pop face over a dark garnet slab.
  final bool primary;
  final bool sunk;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final depth = sunk ? 1.0 : Tokens.buttonDepth;
    return Transform.translate(
      // a sunk key moves down by the slab it lost, so its foot stays put
      offset: Offset(0, Tokens.buttonDepth - depth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: Tokens.keyCorners,
          boxShadow: [
            BoxShadow(
              color: primary ? Tokens.popSlab : Tokens.keySlab,
              offset: Offset(0, depth),
            ),
            if (!sunk)
              BoxShadow(
                color: Tokens.keyShadow,
                offset: Offset(0, depth + 1),
                blurRadius: Tokens.ledGlow,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: Tokens.keyCorners,
          child: HoverMark(
            on: lit,
            child: ColoredBox(
              color: primary ? Tokens.pop : Tokens.keyFace,
              // the lit top edge
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color.fromRGBO(255, 255, 255, Tokens.keyLipAlpha),
                    ),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
