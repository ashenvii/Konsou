import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'motion.dart';

/// Fades its child in when [visible] turns true and out when it turns false.
/// The child stays built, and takes no pointer, while it leaves. A null
/// [child] while leaving keeps the last one shown until it is gone. Something
/// inside that moves as it arrives reads the fade from [shownOf].
class Presence extends StatefulWidget {
  const Presence({
    super.key,
    required this.visible,
    required this.child,
    this.openTime = Tokens.motionOpen,
    this.onGone,
  });

  final bool visible;
  final Widget? child;
  final Duration openTime;

  /// Called once the fade out has finished.
  final VoidCallback? onGone;

  /// The nearest Presence's fade, 0 gone and 1 shown, eased.
  static Animation<double>? shownOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Shown>()?.animation;

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
  // keeps the way-in curve if it is closed halfway in, so nothing jumps
  late final _shown = CurvedAnimation(
    parent: _controller,
    curve: _easeOut,
    reverseCurve: _easeIn,
  );
  Widget? _kept;

  @override
  void initState() {
    super.initState();
    _kept = widget.child;
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
    if (status != AnimationStatus.dismissed || widget.visible) return;
    widget.onGone?.call();
    if (!mounted) return;
    // gone: nothing is built, and the kept child was only for the fade
    setState(() {
      if (widget.child == null) _kept = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = _kept;
    if (child == null || (!widget.visible && _controller.isDismissed)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      ignoring: !widget.visible,
      // the fade is the layer's alpha: no rebuild and no repaint per frame
      child: FadeTransition(
        opacity: _shown,
        // a screen reader hears it at once, not after the fade
        alwaysIncludeSemantics: true,
        child: _Shown(animation: _shown, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _shown.dispose();
    _controller.dispose();
    super.dispose();
  }
}

class _Shown extends InheritedWidget {
  const _Shown({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_Shown old) => old.animation != animation;
}
