import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// Episodes watched out of [total], drawn as one clickable step per episode
/// for a short title (up to [maxSteps], or [narrowSteps] on a narrow window),
/// else as one plain line.
class EntryProgress extends StatefulWidget {
  const EntryProgress({
    super.key,
    required this.watched,
    required this.total,
    required this.onStep,
  });

  static const maxSteps = 24;
  static const narrowSteps = 12;
  static const narrowWidth = 480.0;
  static const stepHeight = 8.0;
  static const lineHeight = 4.0;
  static const _gap = 1.0;

  final int watched;
  final int total;

  /// A step was clicked: the count to set.
  final ValueChanged<int>? onStep;

  static bool drawsSteps(double width, int total) =>
      total > 0 && total <= (width < narrowWidth ? narrowSteps : maxSteps);

  @override
  State<EntryProgress> createState() => _EntryProgressState();
}

class _EntryProgressState extends State<EntryProgress> {
  int? _hover;

  int _stepAt(double dx, double width) =>
      (dx / (width / widget.total)).floor().clamp(0, widget.total - 1) + 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final steps = EntryProgress.drawsSteps(width, widget.total);
        final height = steps
            ? EntryProgress.stepHeight
            : EntryProgress.lineHeight;
        final painter = CustomPaint(
          size: Size(width, height),
          painter: _ProgressPainter(
            watched: widget.watched,
            total: widget.total,
            steps: steps,
            hover: _hover,
          ),
        );
        if (!steps || widget.onStep == null) {
          return SizedBox(height: height, child: painter);
        }
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (e) =>
              setState(() => _hover = _stepAt(e.localPosition.dx, width)),
          onExit: (_) => setState(() => _hover = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => widget.onStep!(_stepAt(d.localPosition.dx, width)),
            child: SizedBox(height: height, child: painter),
          ),
        );
      },
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.watched,
    required this.total,
    required this.steps,
    required this.hover,
  });

  final int watched;
  final int total;
  final bool steps;
  final int? hover;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final track = Paint()..color = Tokens.line;
    final fill = Paint()..color = Tokens.amber;
    if (!steps) {
      canvas.drawRect(Offset.zero & size, track);
      final share = (watched / total).clamp(0.0, 1.0);
      canvas.drawRect(
        Offset.zero & Size(size.width * share, size.height),
        fill,
      );
      return;
    }
    final step = size.width / total;
    final preview = Paint()..color = Tokens.inkSoft;
    for (var i = 0; i < total; i++) {
      final rect = Rect.fromLTWH(
        i * step,
        0,
        step - EntryProgress._gap,
        size.height,
      );
      final paint = i < watched
          ? fill
          : (hover != null && i < hover! ? preview : track);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.watched != watched ||
      old.total != total ||
      old.steps != steps ||
      old.hover != hover;
}
