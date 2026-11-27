import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import '../design/tokens.dart';

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

/// A placer that puts the child right of the anchor, or left of it when there
/// is no room on the right, at the height [top] gives, kept inside the area
/// up and down.
Placer _beside(double Function(Rect anchor, Size child, Size area) top) =>
    ({
      required Rect anchor,
      required Size child,
      required Size area,
      double gap = 0,
    }) {
      final x = anchor.right + gap + child.width <= area.width
          ? anchor.right + gap
          : max(0.0, anchor.left - gap - child.width);
      final y = top(anchor, child, area);
      return Offset(x, y.clamp(0.0, max(0.0, area.height - child.height)));
    };

/// Beside the anchor, on its right, centred on it; on its left when there is
/// no room on the right. Kept inside the area up and down.
final Placer placeBeside = _beside(
  (anchor, child, area) => anchor.center.dy - child.height / 2,
);

/// How far down a cover the quick panel starts, and how far up from its foot
/// it ends at the second spot.
const coverDrop = 0.2;

/// Beside a card's cover: on its right, on its left when there is no room on
/// the right, the top [coverDrop] of the way down the cover and never where
/// the pointer was. When that runs past the bottom, the second spot: the
/// bottom [coverDrop] of the way up from the cover's foot. Held inside the
/// area if it still does not fit.
final Placer placeBesideCover = _beside((anchor, child, area) {
  final drop = anchor.height * coverDrop;
  final first = anchor.top + drop;
  return first + child.height > area.height
      ? anchor.bottom - drop - child.height
      : first;
});

typedef Placer = Offset Function({
  required Rect anchor,
  required Size child,
  required Size area,
  double gap,
});

/// Lays a floating child out next to an anchor, by one of the placers above.
/// With [shown] it slides [Tokens.openSlide] out of the anchor as it arrives:
/// down when it sits below the anchor, up when it sits above. It leaves with
/// no slide.
class AnchoredLayout extends SingleChildLayoutDelegate {
  AnchoredLayout(this.anchor, this.gap, this.place, {this.shown})
    : super(relayout: shown);

  final Rect anchor;
  final double gap;
  final Placer place;
  final Animation<double>? shown;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final at = place(anchor: anchor, child: childSize, area: size, gap: gap);
    final shown = this.shown;
    if (shown == null || shown.status == AnimationStatus.reverse) return at;
    final towardAnchor = at.dy < anchor.top ? 1.0 : -1.0;
    return at.translate(0, towardAnchor * Tokens.openSlide * (1 - shown.value));
  }

  @override
  bool shouldRelayout(AnchoredLayout oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.gap != gap ||
      oldDelegate.place != place ||
      oldDelegate.shown != shown;
}
