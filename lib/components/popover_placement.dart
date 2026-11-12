import 'dart:math';
import 'dart:ui';

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
