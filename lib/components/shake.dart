import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'motion.dart';

/// Fires a [Shake], and anything else listening, each time [fire] is called.
class ShakeSignal extends ChangeNotifier {
  void fire() => notifyListeners();
}

/// Shakes [child] with two small swings either way, settling at rest, each
/// time [trigger] fires. Still when motion is reduced.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final Listenable trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: Tokens.motionQuick,
  );

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_go);
  }

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      old.trigger.removeListener(_go);
      widget.trigger.addListener(_go);
    }
  }

  void _go() {
    if (chooseMotionDuration(context, Tokens.motionQuick) > Duration.zero) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_go);
    _shake.dispose();
    super.dispose();
  }

  static double _swing(double t) {
    const swings = [0.0, -2.0, 2.0, -1.0, 0.0];
    final at = t * (swings.length - 1);
    final i = at.floor().clamp(0, swings.length - 2);
    return swings[i] + (swings[i + 1] - swings[i]) * (at - i);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _shake,
    builder: (context, child) => Transform.translate(
      offset: Offset(_swing(_shake.value), 0),
      child: child,
    ),
    child: widget.child,
  );
}
