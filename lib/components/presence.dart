import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'motion.dart';

/// Fades its child in when [visible] turns true and out when it turns false.
/// The child stays built, and takes no pointer, while it leaves. With [slide]
/// it also drops [Tokens.openSlide] on the way in; the way out is a fade only.
/// A null [child] while leaving keeps the last one shown until it is gone.
class Presence extends StatefulWidget {
  const Presence({
    super.key,
    required this.visible,
    required this.child,
    this.slide = false,
    this.openTime = Tokens.motionOpen,
    this.onGone,
  });

  final bool visible;
  final Widget? child;
  final bool slide;
  final Duration openTime;

  /// Called once the fade out has finished.
  final VoidCallback? onGone;

  @override
  State<Presence> createState() => _PresenceState();
}

// Windows' own easing: decelerate in, accelerate out
const _easeOut = Cubic(0, 0, 0.2, 1);
const _easeIn = Cubic(0.4, 0, 1, 1);

class _PresenceState extends State<Presence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener(_status);
  Widget? _kept;

  @override
  void initState() {
    super.initState();
    _kept = widget.child;
    if (widget.visible) _controller.value = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller
      ..duration = chooseMotionDuration(context, widget.openTime)
      ..reverseDuration = chooseMotionDuration(context, Tokens.motionClose);
    if (widget.visible &&
        _controller.status == AnimationStatus.dismissed &&
        !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(Presence old) {
    super.didUpdateWidget(old);
    if (widget.child != null) _kept = widget.child;
    if (widget.visible && !old.visible) _controller.forward();
    if (!widget.visible && old.visible) _controller.reverse();
  }

  void _status(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !widget.visible) {
      widget.onGone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _kept;
    if (child == null) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedBuilder(
        animation: _controller,
        child: child,
        builder: (context, child) {
          // gone: nothing is built, the fade has finished
          if (!widget.visible && _controller.isDismissed) {
            return const SizedBox.shrink();
          }
          final opening = _controller.status != AnimationStatus.reverse;
          final t = (opening ? _easeOut : _easeIn).transform(_controller.value);
          return Opacity(
            opacity: t,
            // a screen reader hears it at once, not after the fade
            alwaysIncludeSemantics: true,
            child: Transform.translate(
              offset: Offset(
                0,
                widget.slide && opening ? -Tokens.openSlide * (1 - t) : 0,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
