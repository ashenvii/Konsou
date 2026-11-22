import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'motion.dart';

// how strongly a turning half leans toward the viewer
const _depth = 0.006;

/// A split flap: when [face] changes, the old [child] falls out of the top
/// half and the new one swings down into the bottom half with a small bounce,
/// as on a departures board. At rest it is only [child], with no plate behind
/// it; [plate] fills the halves while they turn.
class Flap extends StatefulWidget {
  const Flap({
    super.key,
    required this.face,
    required this.plate,
    required this.child,
    this.duration = Tokens.motionFlap,
  });

  final Object face;
  final Color plate;
  final Widget child;
  final Duration duration;

  @override
  State<Flap> createState() => _FlapState();
}

class _FlapState extends State<Flap> with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this);
  Widget? _old;

  @override
  void didUpdateWidget(Flap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.face == widget.face) return;
    final duration = chooseMotionDuration(context, widget.duration);
    if (duration == Duration.zero) {
      _old = null;
      return;
    }
    // mid-turn, the face that was arriving is the one that falls
    _old = oldWidget.child;
    final turn = ++_turns;
    _turn
      ..duration = duration
      // a turn cut short by the next one must not clear the next one's face
      ..forward(from: 0).whenCompleteOrCancel(() {
        if (mounted && turn == _turns) setState(() => _old = null);
      });
  }

  var _turns = 0;

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final old = _old;
    if (old == null) return widget.child;
    return AnimatedBuilder(
      animation: _turn,
      builder: (context, _) {
        final falling = _turn.value < 0.5;
        final step = falling ? _turn.value * 2 : _turn.value * 2 - 1;
        return Stack(
          children: [
            // the flap is as big as the larger face
            Opacity(opacity: 0, child: old),
            Opacity(opacity: 0, child: widget.child),
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      Expanded(child: _half(widget.child, top: true)),
                      Expanded(child: _half(old, top: false)),
                    ],
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: falling
                            ? _turned(
                                _half(old, top: true),
                                angle:
                                    -Curves.easeIn.transform(step) *
                                    math.pi /
                                    2,
                                shade: step * Tokens.flapShade,
                                top: true,
                              )
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: falling
                            ? const SizedBox.shrink()
                            : _turned(
                                _half(widget.child, top: false),
                                angle: _swing(step),
                                shade: (1 - step) * Tokens.flapShade,
                                top: false,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // from flat away (90 degrees) past flat by flapBounce, then back to rest
  double _swing(double step) {
    const radians = math.pi / 180;
    if (step < 0.8) {
      final eased = Curves.easeOut.transform(step / 0.8);
      return (90 - (90 + Tokens.flapBounce) * eased) * radians;
    }
    return -Tokens.flapBounce * (1 - (step - 0.8) / 0.2) * radians;
  }

  // one half of a face, the face standing at the flap's full height
  Widget _half(Widget face, {required bool top}) => ClipRect(
    child: LayoutBuilder(
      builder: (context, size) => OverflowBox(
        alignment: top ? Alignment.topLeft : Alignment.bottomLeft,
        minHeight: size.maxHeight * 2,
        maxHeight: size.maxHeight * 2,
        child: ColoredBox(
          color: widget.plate,
          child: Align(alignment: Alignment.centerLeft, child: face),
        ),
      ),
    ),
  );

  Widget _turned(
    Widget half, {
    required double angle,
    required double shade,
    required bool top,
  }) => Transform(
    alignment: top ? Alignment.bottomCenter : Alignment.topCenter,
    transform: Matrix4.identity()
      ..setEntry(3, 2, _depth)
      ..rotateX(angle),
    child: Stack(
      fit: StackFit.expand,
      children: [
        half,
        ColoredBox(color: Tokens.ground.withValues(alpha: shade)),
      ],
    ),
  );
}
