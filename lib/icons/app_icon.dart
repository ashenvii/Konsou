import 'package:flutter/widgets.dart';

import 'icon_def.dart';

/// Draws an [IconDef] [size] wide, as tall as its grid is. The fills use
/// [color]; the lines use [lineColor], or [color] when none is given.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.def, {
    super.key,
    required this.size,
    required this.color,
    this.lineColor,
  });

  final IconDef def;
  final double size;
  final Color color;
  final Color? lineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * def.rows / def.columns,
      child: CustomPaint(painter: _IconPainter(def, color, lineColor ?? color)),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.def, this.fillColor, this.lineColor);

  final IconDef def;
  final Color fillColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / def.columns;
    Offset at(GridPoint p) => Offset(p.$1 * unit, p.$2 * unit);

    void drawShapes(List<List<GridPoint>> shapes, Paint paint) {
      for (final shape in shapes) {
        final start = at(shape.first);
        final path = Path()..moveTo(start.dx, start.dy);
        for (final p in shape.skip(1)) {
          path.lineTo(at(p).dx, at(p).dy);
        }
        canvas.drawPath(path..close(), paint);
      }
    }

    drawShapes(def.fills, Paint()..color = fillColor);
    // A shade is a solid shape in the line color, drawn over the fills.
    drawShapes(def.shades, Paint()..color = lineColor);

    Paint stroke(double width) => Paint()
      ..color = lineColor
      ..strokeWidth = unit * width
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter
      ..style = PaintingStyle.stroke;
    // lines that meet are drawn as one path, so a corner is a joint and not
    // two square ends sticking out past each other
    void drawLines(List<GridLine> lines, Paint paint) {
      Path? path;
      GridPoint? start;
      GridPoint? end;
      void finish() {
        if (path == null) return;
        if (end == start) path.close();
        canvas.drawPath(path, paint);
      }

      for (final (a, b) in lines) {
        if (path == null || a != end) {
          finish();
          path = Path()..moveTo(at(a).dx, at(a).dy);
          start = a;
        }
        path.lineTo(at(b).dx, at(b).dy);
        end = b;
      }
      finish();
    }

    if (def.mascot) {
      // the mascot keeps the tuned look: each line on its own, square ends
      for (final (width, lines) in [
        (def.lineWidth, def.lines),
        (def.thinWidth, def.thinLines),
      ]) {
        final paint = stroke(width)..strokeCap = StrokeCap.square;
        for (final (a, b) in lines) {
          canvas.drawLine(at(a), at(b), paint);
        }
      }
      return;
    }
    drawLines(def.lines, stroke(def.lineWidth));
    drawLines(def.thinLines, stroke(def.thinWidth));
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.def != def ||
      old.fillColor != fillColor ||
      old.lineColor != lineColor;
}
