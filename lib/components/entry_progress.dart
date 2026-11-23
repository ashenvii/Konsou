import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'motion.dart';

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

class _EntryProgressState extends State<EntryProgress>
    with SingleTickerProviderStateMixin {
  int? _hover;

  // a change lights the new segments, or darkens the dropped ones, over a
  // moment instead of at once
  late final _light = AnimationController(vsync: this, value: 1);
  late final _lit = CurvedAnimation(parent: _light, curve: Curves.easeOut);
  late int _from = widget.watched;

  @override
  void didUpdateWidget(EntryProgress old) {
    super.didUpdateWidget(old);
    // a mouse region that goes away never calls its exit
    if (widget.onStep == null) _hover = null;
    if (old.watched == widget.watched) return;
    _from = old.watched;
    _light
      ..duration = chooseMotionDuration(context, Tokens.motionSegment)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _lit.dispose();
    _light.dispose();
    super.dispose();
  }

  int _stepAt(double dx, double width) =>
      (dx / (width / widget.total)).floor().clamp(0, widget.total - 1) + 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final steps = EntryProgress.drawsSteps(width, widget.total);
        final interactive = steps && widget.onStep != null;
        final height = steps
            ? EntryProgress.stepHeight
            : EntryProgress.lineHeight;
        final painter = CustomPaint(
          size: Size(width, height),
          painter: _ProgressPainter(
            watched: widget.watched,
            from: _from,
            lit: _lit,
            total: widget.total,
            steps: steps,
            hover: interactive ? _hover : null,
          ),
        );
        if (!interactive) {
          return _Display(
            child: SizedBox(height: height, child: painter),
          );
        }
        // the minus and plus keys beside it are what a screen reader uses
        return _Display(
          child: ExcludeSemantics(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onHover: (e) =>
                  setState(() => _hover = _stepAt(e.localPosition.dx, width)),
              onExit: (_) => setState(() => _hover = null),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) =>
                    widget.onStep!(_stepAt(d.localPosition.dx, width)),
                child: SizedBox(height: height, child: painter),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The sunk well the segments sit in.
class _Display extends StatelessWidget {
  const _Display({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Tokens.displayInset),
    decoration: const BoxDecoration(
      color: Tokens.wellFill,
      borderRadius: Tokens.coverCorners,
      boxShadow: [BoxShadow(color: Tokens.edgeLight, offset: Offset(0, 1))],
    ),
    child: child,
  );
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.watched,
    required this.from,
    required this.lit,
    required this.total,
    required this.steps,
    required this.hover,
  }) : super(repaint: lit);

  final int watched;

  /// The count before the last change, and how far the change has come.
  final int from;
  final Animation<double> lit;
  final int total;
  final bool steps;
  final int? hover;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final track = Paint()..color = Tokens.lampOff;
    final fill = Paint()..color = Tokens.pop;
    // lit segments glow a little, like the LED digits beside them
    final glow = Paint()
      ..color = Tokens.pop.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        Tokens.ledGlow / 2,
      );
    final t = lit.value;
    if (!steps) {
      canvas.drawRect(Offset.zero & size, track);
      final count = from + (watched - from) * t;
      final share = (count / total).clamp(0.0, 1.0);
      final lit = Offset.zero & Size(size.width * share, size.height);
      canvas
        ..drawRect(lit, glow)
        ..drawRect(lit, fill);
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
      final was = i < from;
      final now = i < watched;
      // how lit: steady on either side of a change, turning on with t or
      // off with 1 - t
      final on = was == now ? (now ? 1.0 : 0.0) : (now ? t : 1 - t);
      if (on <= 0) {
        canvas.drawRect(rect, hover != null && i < hover! ? preview : track);
        continue;
      }
      if (on >= 1) {
        canvas
          ..drawRect(rect, glow)
          ..drawRect(rect, fill);
        continue;
      }
      canvas
        ..drawRect(rect, track)
        ..drawRect(
          rect,
          Paint()
            ..color = Tokens.pop.withValues(alpha: 0.5 * on)
            ..maskFilter = glow.maskFilter,
        )
        ..drawRect(rect, Paint()..color = Tokens.pop.withValues(alpha: on));
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.watched != watched ||
      old.from != from ||
      old.total != total ||
      old.steps != steps ||
      old.hover != hover;
}
