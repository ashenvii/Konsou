import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'countdown.dart';
import 'countdown_builder.dart';
import 'focus_ring.dart';
import 'raised_key.dart';
import 'shake.dart';

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

/// A press of the main button starts the hold; a right or middle click is no
/// hold.
void holdOnPointer(PointerDownEvent event, VoidCallback start) {
  if (event.buttons & kPrimaryButton != 0) start();
}

/// What a hold-to-remove key keeps: the hold, the signal fired when it is let
/// go early, the pointer and focus state, and the handlers that drive them.
mixin HoldPress<T extends StatefulWidget> on State<T> {
  late final hold = Countdown(onDone: () => holdDone());
  final early = ShakeSignal();
  var hovered = false;
  var focused = false;

  Duration get holdTime;

  void holdDone();

  /// Called when the hold is let go before it was done, before [early] fires.
  void letGoEarly() {}

  void startHold() => hold.start(holdTime);

  void stopHold() {
    final wasEarly = hold.running;
    hold.cancel();
    if (!wasEarly) return;
    letGoEarly();
    early.fire();
  }

  KeyEventResult holdKey(FocusNode node, KeyEvent event) =>
      holdOnKeys(event, start: startHold, stop: stopHold);

  void holdPointer(PointerDownEvent event) => holdOnPointer(event, startHold);

  void focusChanged(bool on) {
    setState(() => focused = on);
    if (!on) hold.cancel();
  }

  @override
  void dispose() {
    hold.dispose();
    early.dispose();
    super.dispose();
  }
}

/// The key a [HoldPress] draws: raised, sunk once held, the red rising
/// through it, ringed on focus, shaken when let go early. [face] is drawn on
/// it and is told whether the hold is running.
class HoldKey extends StatelessWidget {
  const HoldKey({
    super.key,
    required this.press,
    required this.lit,
    required this.face,
  });

  final HoldPress press;
  final bool lit;
  final Widget Function(bool running) face;

  @override
  Widget build(BuildContext context) {
    final hold = press.hold;
    return Shake(
      trigger: press.early,
      child: CountdownBuilder(
        countdown: hold,
        builder: (context, share, running) => FocusRing(
          on: press.focused,
          corners: Tokens.keyCorners,
          child: RaisedKey(
            lit: lit,
            sunk: hold.started,
            child: Stack(
              children: [
                // empty until held, full when the hold is done
                HoldFill(share: hold.started ? 1 - share : 0.0),
                face(running),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
