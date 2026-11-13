import 'dart:math';

import 'package:flutter/rendering.dart';

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

/// Beside the anchor, on its right, centred on it; on its left when there is
/// no room on the right. Kept inside [area] up and down.
Offset placeBeside({
  required Rect anchor,
  required Size child,
  required Size area,
  double gap = 0,
}) {
  final fitsRight = anchor.right + gap + child.width <= area.width;
  final x = fitsRight
      ? anchor.right + gap
      : max(0.0, anchor.left - gap - child.width);
  final y = max(
    0.0,
    min(anchor.center.dy - child.height / 2, area.height - child.height),
  );
  return Offset(x, y);
}

typedef Placer = Offset Function({
  required Rect anchor,
  required Size child,
  required Size area,
  double gap,
});

/// Lays a floating child out next to an anchor, by one of the placers above.
class AnchoredLayout extends SingleChildLayoutDelegate {
  AnchoredLayout(this.anchor, this.gap, this.place);

  final Rect anchor;
  final double gap;
  final Placer place;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      place(anchor: anchor, child: childSize, area: size, gap: gap);

  @override
  bool shouldRelayout(AnchoredLayout oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.gap != gap ||
      oldDelegate.place != place;
}
