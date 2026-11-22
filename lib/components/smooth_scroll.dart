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

// how far one wheel notch goes, against the platform's own step
const wheelBoost = 1.4;

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
  Duration? _began;
  double _target = 0;
  double _speed = 0;

  // where the spring is, unrounded; what is drawn is this on a whole pixel
  double _at = 0;

  bool get _gliding => _ticker?.isActive ?? false;

  double _ratio = 1;

  // every frame of the glide is drawn on a whole device pixel, not only its
  // rest: a picture cached on its own layer is drawn on whole pixels while
  // the page around it is not, and at a fraction between them a seam shows.
  // Only the drawn place is rounded; the spring runs on [_at], so rounding
  // can never hold it short of its stop
  double _snap(double offset) => (offset * _ratio).roundToDouble() / _ratio;

  // a glide that has not landed by now lands anyway: while it runs the page
  // takes no clicks, so it must always end
  static const _longest = Duration(seconds: 2);

  @override
  void pointerScroll(double delta) {
    if (delta == 0) return;
    final still = MediaQuery.maybeDisableAnimationsOf(
      context.notificationContext!,
    );
    if (still ?? false) return super.pointerScroll(delta);
    final from = _gliding ? _target : pixels;
    // the glide rests on a whole device pixel, so glows, masks and the pinned
    // bar's edge are drawn the same way at every stop, not shifted by half a
    // pixel on every other notch
    _ratio =
        MediaQuery.maybeDevicePixelRatioOf(context.notificationContext!) ?? 1;
    final target = _snap(from + delta * wheelBoost);
    final clamped = target.clamp(minScrollExtent, maxScrollExtent);
    if (clamped == from) return;
    _target = clamped;
    if (_gliding) return;
    _speed = 0;
    _last = null;
    _began = null;
    _at = pixels;
    beginActivity(_GlideActivity(this, () => _speed));
    (_ticker ??= context.vsync.createTicker(_tick)).start();
  }

  void _tick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    final began = _began ??= elapsed;
    if (last == null) return;
    // a long frame must not throw the spring past its target
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _target = _target.clamp(minScrollExtent, maxScrollExtent);
    final gap = _at - _target;
    final carry = _speed + _pull * gap;
    final fade = math.exp(-_pull * dt);
    final nextGap = (gap + carry * dt) * fade;
    _speed = (carry - _pull * (gap + carry * dt)) * fade;
    if ((nextGap.abs() < 0.4 && _speed.abs() < 8) ||
        elapsed - began > _longest) {
      setPixels(_target);
      _finish();
      return;
    }
    _at = _target + nextGap;
    final overscroll = setPixels(_snap(_at));
    if (overscroll != 0) _finish();
  }

  void _finish() {
    _stop();
    goBallistic(0);
  }

  void _stop() {
    _ticker?.stop();
    _last = null;
    _began = null;
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
