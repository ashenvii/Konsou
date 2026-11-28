import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'down_fade.dart';
import 'focus_ring.dart';
import 'hover_mark.dart';
import 'sunk_decoration.dart';

/// A well sunk into the page: near black, shaded at its top where what is
/// above overhangs it, a faint lit lip under it. The title bar's search and
/// every text field are this. [hovered] is the live edge; [focused] rings it
/// in ink.
///
/// A well with no [height] grows with its [child] from [minHeight]. The lip
/// is drawn [lip] below the box, so whatever clips this must leave that much
/// room.
class SunkWell extends StatelessWidget {
  const SunkWell({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.minHeight = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: Tokens.space2),
    this.hovered = false,
    this.focused = false,
  });

  final double? width;
  final double? height;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final bool hovered;
  final bool focused;
  final Widget child;

  /// How far [wellLip] hangs below the box.
  static const lip = 1.0;

  @override
  Widget build(BuildContext context) {
    // the shade covers the top quarter of a one-line well; a taller well
    // keeps that depth
    final shade = (height ?? Tokens.controlHeight - lip) * 0.25;
    return FocusRing(
      on: focused,
      corners: Tokens.keyCorners,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: Tokens.keyCorners,
          boxShadow: [wellLip],
        ),
        child: ClipRRect(
          borderRadius: Tokens.keyCorners,
          child: HoverMark(
            on: hovered,
            child: Container(
              // no alignment: an aligned Container grows to fill its parent
              // and its fill paints over everything beside it
              width: width,
              height: height,
              constraints: BoxConstraints(minHeight: minHeight),
              color: Tokens.wellFill,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Padding(padding: padding, child: child),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: shade,
                    child: IgnorePointer(
                      child: DownFade(
                        colors: [
                          Tokens.shadow,
                          Tokens.shadow.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
