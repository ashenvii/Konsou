import 'package:flutter/widgets.dart';

import '../../components/dashes.dart';
import '../../components/state_square.dart';
import '../../design/tokens.dart';
import '../../library/entry_status.dart';

/// One stop on the line through the watch order: the state square and a line
/// on to the next card's square, solid once travelled and dashed ahead.
class WatchOrderRail extends StatelessWidget {
  const WatchOrderRail({
    super.key,
    required this.status,
    required this.label,
    required this.share,
    required this.travelled,
    this.reachToNext,
  });

  final EntryStatus? status;
  final String label;
  final double share;

  /// Whether the line to the next square is behind you.
  final bool travelled;

  /// The distance from this card's left edge to the next card's, or null for
  /// the last card, which has no line on.
  final double? reachToNext;

  @override
  Widget build(BuildContext context) {
    const centre = Tokens.stateSquare / 2;
    final reach = reachToNext;
    return SizedBox(
      height: Tokens.railLaneHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (reach != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _LinePainter(to: reach + centre, travelled: travelled),
              ),
            ),
          Positioned(
            left: 0,
            top: (Tokens.railLaneHeight - Tokens.stateSquare) / 2,
            child: StateSquare(status: status, label: label, share: share),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.to, required this.travelled});

  final double to;
  final bool travelled;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Path()
      ..moveTo(Tokens.stateSquare / 2, y)
      ..lineTo(to, y);
    canvas.drawPath(
      travelled ? line : dashedPath(line, Tokens.railDash, Tokens.railDash),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Tokens.focusRing
        ..color = travelled ? Tokens.inkMuted : Tokens.line,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.to != to || old.travelled != travelled;
}
