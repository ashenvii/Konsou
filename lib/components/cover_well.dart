import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'motion.dart';

/// A cover sunk into the console: a near-black well around it, shaded at the
/// top, with a faint lit lip under it. [lit] (hover or focus) rings the well in
/// pop and lifts the cover a little.
class CoverWell extends StatelessWidget {
  const CoverWell({super.key, required this.child, this.lit = false});

  final Widget child;
  final bool lit;

  /// How much narrower the cover is than the well.
  static const inset = Tokens.wellPad * 2;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Tokens.wellFill,
        borderRadius: Tokens.wellCorners,
        boxShadow: [BoxShadow(color: Tokens.edgeLight, offset: Offset(0, 1))],
      ),
      position: DecorationPosition.background,
      child: Container(
        padding: const EdgeInsets.all(Tokens.wellPad),
        foregroundDecoration: BoxDecoration(
          borderRadius: Tokens.wellCorners,
          border: Border.all(
            color: Tokens.pop.withValues(alpha: lit ? 0.6 : 0),
          ),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: lit ? -Tokens.hoverEdge : 0),
          duration: chooseMotionDuration(context, Tokens.motionQuick),
          curve: Curves.easeOut,
          child: ClipRRect(borderRadius: Tokens.coverCorners, child: child),
          builder: (context, dy, child) =>
              Transform.translate(offset: Offset(0, dy), child: child),
        ),
      ),
    );
  }
}
