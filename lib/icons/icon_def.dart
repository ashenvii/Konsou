/// A point on the icon grid. Whole numbers only.
typedef GridPoint = (int, int);

/// One straight line between two grid points.
typedef GridLine = (GridPoint, GridPoint);

/// An icon as straight lines on a fixed grid of [columns] by [rows] units.
/// [fills] are closed shapes painted solid, [lines] are strokes [lineWidth]
/// units thick, and [thinLines] are strokes [thinWidth] units thick for fine
/// detail.
/// [shades] are closed shapes painted in the line color over the fills, such
/// as the dark inside of an ear. Every edge must be horizontal, vertical or 45
/// degrees. [badEdges] reports the ones that are not.
class IconDef {
  const IconDef({
    this.columns = 16,
    int? rows,
    this.lineWidth = 1,
    this.thinWidth = 1,
    this.fills = const [],
    this.shades = const [],
    this.lines = const [],
    this.thinLines = const [],
  }) : rows = rows ?? columns;

  final int columns;
  final int rows;
  final double lineWidth;
  final double thinWidth;
  final List<List<GridPoint>> fills;
  final List<List<GridPoint>> shades;
  final List<GridLine> lines;
  final List<GridLine> thinLines;

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
        final inside =
            p.$1 >= 0 && p.$1 <= columns && p.$2 >= 0 && p.$2 <= rows;
        if (!inside) {
          problems.add('$where: $p is outside the $columns by $rows grid');
        }
      }
    }

    for (final (i, line) in lines.indexed) {
      check('line $i', line.$1, line.$2);
    }
    for (final (i, line) in thinLines.indexed) {
      check('thin line $i', line.$1, line.$2);
    }
    void checkShape(String name, int i, List<GridPoint> shape) {
      for (var j = 0; j < shape.length; j++) {
        check('$name $i edge $j', shape[j], shape[(j + 1) % shape.length]);
      }
    }

    for (final (i, shape) in fills.indexed) {
      checkShape('fill', i, shape);
    }
    for (final (i, shape) in shades.indexed) {
      checkShape('shade', i, shape);
    }
    return problems;
  }
}
