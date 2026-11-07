import 'dart:math';

/// A rectangle in whole screen pixels.
class PixelRect {
  const PixelRect(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left;
  int get height => bottom - top;

  @override
  bool operator ==(Object other) =>
      other is PixelRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'PixelRect($left, $top, $right, $bottom)';
}

/// Moves [want] onto [work] the way Windows does for a window that was left
/// off screen: the size is kept, only the position slides in. The size shrinks
/// only when the window is bigger than the work area.
PixelRect fitIntoWorkArea(PixelRect want, PixelRect work) {
  final width = min(want.width, work.width);
  final height = min(want.height, work.height);
  final left = want.left.clamp(work.left, work.right - width);
  final top = want.top.clamp(work.top, work.bottom - height);
  return PixelRect(left, top, left + width, top + height);
}
