import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'motion.dart';

/// A picture with its colour taken out and dimmed to half while [on], easing
/// back to full colour when it turns off.
class Faded extends StatelessWidget {
  const Faded({super.key, required this.on, required this.child});

  final bool on;
  final Widget child;

  // the share of each channel in a grey of the same lightness
  static const _redShare = 0.2126;
  static const _greenShare = 0.7152;
  static const _blueShare = 0.0722;
  static const _dim = 0.5;

  static List<double> _matrix(double fade) {
    double mix(double from, double to) => from + (to - from) * fade;
    List<double> channel(int index) {
      final keep = [0.0, 0.0, 0.0]..[index] = 1.0;
      return [
        mix(keep[0], _redShare * _dim),
        mix(keep[1], _greenShare * _dim),
        mix(keep[2], _blueShare * _dim),
        0,
        0,
      ];
    }

    return [...channel(0), ...channel(1), ...channel(2), 0, 0, 0, 1, 0];
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: on ? 1 : 0),
      duration: chooseMotionDuration(context, Tokens.motionQuick),
      curve: Curves.easeOut,
      child: child,
      // filtered even at no fade, so the cover is not remounted on every hover
      builder: (context, fade, child) => ColorFiltered(
        colorFilter: ColorFilter.matrix(_matrix(fade)),
        child: child,
      ),
    );
  }
}
