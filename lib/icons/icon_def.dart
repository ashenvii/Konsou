/// A point on the icon grid. Whole numbers only.
typedef GridPoint = (int, int);

/// One straight line between two grid points.
typedef GridLine = (GridPoint, GridPoint);

/// An icon as straight lines on a fixed grid. [fills] are closed shapes
/// painted solid, [lines] are strokes one grid unit thick. Every edge must be
/// horizontal, vertical or 45 degrees. [badEdges] reports the ones that are not.
class IconDef {
  const IconDef({
    this.grid = 16,
    this.fills = const [],
    this.lines = const [],
  });

  final int grid;
  final List<List<GridPoint>> fills;
  final List<GridLine> lines;

  /// Every edge that breaks the angle rule or leaves the grid, as text.
  List<String> badEdges() {
    final problems = <String>[];
    void check(String where, GridPoint a, GridPoint b) {
      final dx = (b.$1 - a.$1).abs();
      final dy = (b.$2 - a.$2).abs();
      final straight = (dx == 0) != (dy == 0);
      final diagonal = dx == dy && dx != 0;
      if (!straight && !diagonal) problems.add('$where: $a to $b');
      for (final p in [a, b]) {
        final inside = p.$1 >= 0 && p.$1 <= grid && p.$2 >= 0 && p.$2 <= grid;
        if (!inside) problems.add('$where: $p is outside the $grid grid');
      }
    }

    for (final (i, line) in lines.indexed) {
      check('line $i', line.$1, line.$2);
    }
    for (final (i, shape) in fills.indexed) {
      for (var j = 0; j < shape.length; j++) {
        check('fill $i edge $j', shape[j], shape[(j + 1) % shape.length]);
      }
    }
    return problems;
  }
}
