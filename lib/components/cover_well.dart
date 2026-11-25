import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// A cover sunk into the console: a near-black well around it, shaded at the
/// top, with a faint lit lip under it. [lit] (hover or focus) rings the well
/// in pop. A [foot] sits in the well under the cover, which then has no
/// padding below it.
class CoverWell extends StatelessWidget {
  const CoverWell({
    super.key,
    required this.child,
    this.foot,
    this.lit = false,
  });

  final Widget child;
  final Widget? foot;
  final bool lit;

  /// How much narrower the cover is than the well.
  static const inset = Tokens.wellPad * 2;

  @override
  Widget build(BuildContext context) {
    final foot = this.foot;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Tokens.wellFill,
        borderRadius: Tokens.wellCorners,
        boxShadow: [BoxShadow(color: Tokens.edgeLight, offset: Offset(0, 1))],
      ),
      position: DecorationPosition.background,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          Tokens.wellPad,
          Tokens.wellPad,
          Tokens.wellPad,
          foot == null ? Tokens.wellPad : 0,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: Tokens.wellCorners,
          border: Border.all(
            color: Tokens.pop.withValues(alpha: lit ? 0.6 : 0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: Tokens.coverCorners, child: child),
            ?foot,
          ],
        ),
      ),
    );
  }
}
