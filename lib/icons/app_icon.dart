import 'package:flutter/widgets.dart';

import 'icon_def.dart';

/// Draws an [IconDef] at [size]. The fills use [color]; the lines use
/// [lineColor], or [color] when none is given.
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
    return SizedBox.square(
      dimension: size,
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
    final unit = size.width / def.grid;
    Offset at(GridPoint p) => Offset(p.$1 * unit, p.$2 * unit);

    final fill = Paint()..color = fillColor;
    for (final shape in def.fills) {
      final path = Path()..moveTo(at(shape.first).dx, at(shape.first).dy);
      for (final p in shape.skip(1)) {
        path.lineTo(at(p).dx, at(p).dy);
      }
      canvas.drawPath(path..close(), fill);
    }

    final stroke = Paint()
      ..color = lineColor
      ..strokeWidth = unit
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    for (final (a, b) in def.lines) {
      canvas.drawLine(at(a), at(b), stroke);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.def != def ||
      old.fillColor != fillColor ||
      old.lineColor != lineColor;
}
