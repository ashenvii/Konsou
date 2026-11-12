import 'dart:math';
import 'dart:ui';

/// Where the top left of a popover goes: under [anchor], lined up with its
/// left edge; lined up with its right edge instead when the left alignment
/// would run off the right of [area], so it still hangs off the thing that was
/// clicked; flipped above the anchor when there is no room below. [gap] leaves
/// that much empty space between the anchor and the popover. Never negative,
/// so a menu opened from a wide anchor cannot land off screen.
Offset placePopover({
  required Rect anchor,
  required Size child,
  required Size area,
  double gap = 0,
}) {
  final fitsLeftAligned = anchor.left + child.width <= area.width;
  final x = max(
    0.0,
    min(
      fitsLeftAligned ? anchor.left : anchor.right - child.width,
      area.width - child.width,
    ),
  );
  final below = anchor.bottom + gap;
  final double y;
  if (below + child.height <= area.height) {
    y = below;
  } else if (anchor.top - gap - child.height >= 0) {
    y = anchor.top - gap - child.height;
  } else {
    y = max(0.0, area.height - child.height);
  }
  return Offset(x, y);
}
