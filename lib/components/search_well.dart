import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'hover_mark.dart';

/// A well sunk into the page: near black, shaded at its top where what is
/// above overhangs it, a faint lit lip under it. The title bar's search and
/// the Library's Find are both this. [hovered] is the live edge.
///
/// The lip is drawn [lip] below the box, so whatever clips this must leave
/// that much room.
class SearchWell extends StatelessWidget {
  const SearchWell({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.hovered = false,
  });

  final double width;
  final double height;
  final bool hovered;
  final Widget child;

  static const lip = 1.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: Tokens.keyCorners,
        boxShadow: [BoxShadow(color: Tokens.edgeLight, offset: Offset(0, lip))],
      ),
      child: ClipRRect(
        borderRadius: Tokens.keyCorners,
        child: HoverMark(
          on: hovered,
          child: Container(
            // a fixed size and no alignment: an aligned Container grows to
            // fill its parent and its fill paints over everything beside it
            width: width,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space2),
            decoration: const BoxDecoration(color: Tokens.wellFill),
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Tokens.shadow, Tokens.shadow.withValues(alpha: 0)],
                stops: const [0, 0.25],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
