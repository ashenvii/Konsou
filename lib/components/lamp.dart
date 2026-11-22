import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// The console's small round light: lit in [lit] with a glow, off when null,
/// or an empty ring while [waiting] on something. Never alone: a word or count
/// beside it says what it means.
class Lamp extends StatelessWidget {
  const Lamp({super.key, this.lit, this.waiting = false});

  final Color? lit;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final lit = this.lit;
    return SizedBox.square(
      dimension: Tokens.lampSize,
      child: DecoratedBox(
        decoration: waiting
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Tokens.inkMuted,
                  width: Tokens.lampRing,
                ),
              )
            : BoxDecoration(
                shape: BoxShape.circle,
                color: lit ?? Tokens.lampOff,
                boxShadow: lit == null
                    ? null
                    : [
                        BoxShadow(
                          color: lit.withValues(alpha: 0.6),
                          blurRadius: Tokens.lampGlow,
                        ),
                      ],
              ),
      ),
    );
  }
}
