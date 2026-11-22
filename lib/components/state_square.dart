import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../library/entry_status.dart';

/// A title's state as a small square, in three looks: a filled check for a
/// finished title, an ink fill that rises with the episodes while it is under
/// way, and an empty outline for everything else. The exact status is said in
/// words beside it.
class StateSquare extends StatelessWidget {
  const StateSquare({
    super.key,
    required this.status,
    required this.label,
    this.share = 0,
  });

  /// Null for a title that is not on the list.
  final EntryStatus? status;
  final String label;

  /// How much of a title being watched is done, 0 to 1.
  final double share;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: CustomPaint(
        size: const Size.square(Tokens.stateSquare),
        painter: _SquarePainter(status, share),
      ),
    );
  }
}

class _SquarePainter extends CustomPainter {
  const _SquarePainter(this.status, this.share);

  final EntryStatus? status;
  final double share;

  @override
  void paint(Canvas canvas, Size size) {
    const edge = Tokens.focusRing;
    final box = Offset.zero & size;
    canvas.drawRect(box, Paint()..color = Tokens.ground);

    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = edge
      ..color = color;
    Offset at(double x, double y) => Offset(size.width * x, size.height * y);

    switch (status) {
      case EntryStatus.completed:
        canvas.drawRect(box, Paint()..color = Tokens.inkMuted);
        canvas.drawPath(
          Path()..addPolygon([
            at(0.22, 0.52),
            at(0.42, 0.72),
            at(0.78, 0.3),
          ], false),
          stroke(Tokens.ground),
        );
      case EntryStatus.watching || EntryStatus.rewatching:
        final inner = box.deflate(edge);
        canvas.drawRect(
          Rect.fromLTRB(
            inner.left,
            inner.bottom - inner.height * share.clamp(0, 1),
            inner.right,
            inner.bottom,
          ),
          Paint()..color = Tokens.ink,
        );
        canvas.drawRect(box.deflate(edge / 2), stroke(Tokens.ink));
      default:
        canvas.drawRect(box.deflate(edge / 2), stroke(Tokens.inkMuted));
    }
  }

  @override
  bool shouldRepaint(_SquarePainter old) =>
      old.status != status || old.share != share;
}
