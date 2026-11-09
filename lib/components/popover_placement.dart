import 'dart:math';
import 'dart:ui';

/// Where the top left of a popover goes: under [anchor], lined up with its
/// left edge, pulled back inside [area] when it would run off the right, and
/// flipped above the anchor when there is no room below. Never negative, so a
/// menu opened from a wide anchor cannot land off screen.
Offset placePopover({
  required Rect anchor,
  required Size child,
  required Size area,
}) {
  final x = max(0.0, min(anchor.left, area.width - child.width));
  final below = anchor.bottom;
  final double y;
  if (below + child.height <= area.height) {
    y = below;
  } else if (anchor.top - child.height >= 0) {
    y = anchor.top - child.height;
  } else {
    y = max(0.0, area.height - child.height);
  }
  return Offset(x, y);
}
