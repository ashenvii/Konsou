import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class SmoothScrollController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _GlidingPosition(
    physics: physics,
    context: context,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    oldPosition: oldPosition,
    debugLabel: debugLabel,
  );
}

// settles in about 0.4s, like chrome
const _pull = 14.0;

class _GlidingPosition extends ScrollPositionWithSingleContext {
  _GlidingPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  Ticker? _ticker;
  Duration? _last;
  double _target = 0;
  double _speed = 0;

  bool get _gliding => _ticker?.isActive ?? false;

  @override
  void pointerScroll(double delta) {
    if (delta == 0) return;
    final still = MediaQuery.maybeDisableAnimationsOf(
      context.notificationContext!,
    );
    if (still ?? false) return super.pointerScroll(delta);
    final from = _gliding ? _target : pixels;
    final target = (from + delta).clamp(minScrollExtent, maxScrollExtent);
    if (target == from) return;
    _target = target;
    if (_gliding) return;
    _speed = 0;
    _last = null;
    beginActivity(_GlideActivity(this, () => _speed));
    (_ticker ??= context.vsync.createTicker(_tick)).start();
  }

  void _tick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    if (last == null) return;
    // a long frame must not throw the spring past its target
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _target = _target.clamp(minScrollExtent, maxScrollExtent);
    final gap = pixels - _target;
    final carry = _speed + _pull * gap;
    final fade = math.exp(-_pull * dt);
    final nextGap = (gap + carry * dt) * fade;
    _speed = (carry - _pull * (gap + carry * dt)) * fade;
    if (nextGap.abs() < 0.4 && _speed.abs() < 8) {
      setPixels(_target);
      _finish();
      return;
    }
    final overscroll = setPixels(_target + nextGap);
    if (overscroll != 0) _finish();
  }

  void _finish() {
    _stop();
    goBallistic(0);
  }

  void _stop() {
    _ticker?.stop();
    _last = null;
    _speed = 0;
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    // a drag, a jump or an animation takes over from the glide
    if (_gliding) _stop();
    super.beginActivity(newActivity);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

// counts as scrolling and lets no pointer through, as flutter's own animated
// scrolls do: nothing under a still pointer is hit-tested or hovered each frame
class _GlideActivity extends ScrollActivity {
  _GlideActivity(super.delegate, this._speed);

  final double Function() _speed;

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => _speed();
}

class SmoothScroll extends StatefulWidget {
  const SmoothScroll({super.key, required this.builder});

  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  @override
  State<SmoothScroll> createState() => _SmoothScrollState();
}

class _SmoothScrollState extends State<SmoothScroll> {
  final _controller = SmoothScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
