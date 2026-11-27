import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// The red that rises through a hold-to-remove key from its foot, [share] of
/// the way up (0 until held, 1 when the hold is done).
class HoldFill extends StatelessWidget {
  const HoldFill({super.key, required this.share});

  final double share;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: FractionallySizedBox(
      alignment: Alignment.bottomCenter,
      heightFactor: share,
      child: ColoredBox(color: Tokens.red.withValues(alpha: 0.22)),
    ),
  );
}

/// Enter, numpad Enter and Space hold a hold-to-remove key as a press does:
/// down starts the hold, up lets go.
KeyEventResult holdOnKeys(
  KeyEvent event, {
  required VoidCallback start,
  required VoidCallback stop,
}) {
  if (event.logicalKey != LogicalKeyboardKey.enter &&
      event.logicalKey != LogicalKeyboardKey.numpadEnter &&
      event.logicalKey != LogicalKeyboardKey.space) {
    return KeyEventResult.ignored;
  }
  if (event is KeyDownEvent) start();
  if (event is KeyUpEvent) stop();
  return KeyEventResult.handled;
}
