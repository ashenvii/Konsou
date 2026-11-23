import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'motion.dart';

/// The live edge: a faint pop wash and a line under the child while [on].
/// It fades in and out, so a pointer sweeping across a grid does not flicker.
class HoverMark extends StatelessWidget {
  const HoverMark({super.key, required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: chooseMotionDuration(context, Tokens.motionOpen),
      curve: Curves.easeOut,
      // the off state is the same shape at no alpha, so the two blend
      foregroundDecoration: BoxDecoration(
        color: Tokens.pop.withValues(alpha: on ? 0.06 : 0),
        border: Border(
          bottom: BorderSide(
            color: Tokens.pop.withValues(alpha: on ? 1 : 0),
            width: Tokens.hoverEdge,
          ),
        ),
      ),
      child: child,
    );
  }
}
