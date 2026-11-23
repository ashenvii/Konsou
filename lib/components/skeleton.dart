import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

class SkeletonClock extends ChangeNotifier {
  SkeletonClock._();

  static final instance = SkeletonClock._();

  static const sweep = Duration(milliseconds: 1200);

  final _watch = Stopwatch()..start();
  var _listening = 0;
  var _scheduled = false;

  bool get ticking => _listening > 0;

  double get phase =>
      (_watch.elapsedMicroseconds % sweep.inMicroseconds) /
      sweep.inMicroseconds;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _listening++;
    _schedule();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _listening--;
  }

  void _schedule() {
    if (_scheduled || _listening <= 0) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _scheduled = false;
      if (_listening <= 0) return;
      notifyListeners();
      _schedule();
    });
  }
}

class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: width,
      height: height,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SkeletonPainter(still ? null : SkeletonClock.instance),
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter(this.clock) : super(repaint: clock);

  final SkeletonClock? clock;

  static const _bandShare = 1 / 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Tokens.surface);
    final clock = this.clock;
    if (clock == null) return;
    final band = size.width * _bandShare;
    // eases in and out, so it reads as light passing over, not a wipe
    final left =
        -band + (size.width + band) * Curves.easeInOut.transform(clock.phase);
    final rect = Rect.fromLTWH(left, 0, band, size.height);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Tokens.ink.withValues(alpha: 0),
            Tokens.ink.withValues(alpha: 0.09),
            Tokens.ink.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkeletonPainter oldDelegate) =>
      oldDelegate.clock != clock;
}
