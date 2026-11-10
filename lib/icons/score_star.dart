import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The score star: a plain filled five-point star. It is the one icon not on
/// the 45 degree grid, because a star that reads as a star needs its own
/// angles. [size] is its width and height.
class ScoreStar extends StatelessWidget {
  const ScoreStar({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _StarPainter(color)),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.color);

  final Color color;

  // the inner points sit at this share of the outer radius; 0.382 is the
  // sharp textbook star, this is the fuller one rating stars use
  static const _innerShare = 0.5;
  static const _points = 5;
  static const _rounding = 0.14;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    // the stroke rounds the corners, so the points stay inside the box
    final rounding = size.width * _rounding;
    final outer = size.width / 2 - rounding / 2;
    final inner = outer * _innerShare;
    final path = Path();
    for (var i = 0; i < _points * 2; i++) {
      final radius = i.isEven ? outer : inner;
      // start pointing straight up
      final angle = -math.pi / 2 + i * math.pi / _points;
      final point = centre + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = rounding
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
