import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'countdown.dart';
import 'countdown_builder.dart';
import 'focus_ring.dart';
import 'hold_fill.dart';
import 'hover_tip.dart';
import 'motion.dart';
import 'raised_key.dart';

/// The trash key: hold it for [holdTime] to remove. Its bin is quiet at rest
/// and red under the pointer, on focus and while held; the hold rises red
/// through the key from its foot and drains back out if let go early. The
/// pointer resting on it says [words]. A tap, too short to remove, shakes the
/// key and says "Hold to remove" at once instead of doing nothing.
class RemoveKey extends StatefulWidget {
  const RemoveKey({
    super.key,
    required this.words,
    required this.holdTime,
    required this.onDone,
  });

  /// What holding removes, such as "Hold to remove all 3 seasons".
  final String words;
  final Duration holdTime;
  final VoidCallback onDone;

  static const tapWords = 'Hold to remove';

  @override
  State<RemoveKey> createState() => _RemoveKeyState();
}

class _RemoveKeyState extends State<RemoveKey>
    with SingleTickerProviderStateMixin {
  late final Countdown _hold = Countdown(onDone: () => widget.onDone());
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: Tokens.motionQuick,
  );
  final _reveal = _Signal();
  var _hovered = false;
  var _focused = false;
  var _tapped = false;

  void _start() {
    setState(() => _tapped = false);
    _hold.start(widget.holdTime);
  }

  void _stop() {
    final early = _hold.running;
    _hold.cancel();
    if (!early) return;
    // let go before the hold was done: show how it works
    setState(() => _tapped = true);
    _reveal.fire();
    if (chooseMotionDuration(context, Tokens.motionQuick) > Duration.zero) {
      _shake.forward(from: 0);
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) =>
      holdOnKeys(event, start: _start, stop: _stop);

  @override
  void dispose() {
    _hold.dispose();
    _shake.dispose();
    _reveal.dispose();
    super.dispose();
  }

  // two small swings either way, settling at rest
  static double _swing(double t) {
    const swings = [0.0, -2.0, 2.0, -1.0, 0.0];
    final at = t * (swings.length - 1);
    final i = at.floor().clamp(0, swings.length - 2);
    return swings[i] + (swings[i + 1] - swings[i]) * (at - i);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.words,
      onLongPress: widget.onDone,
      child: HoverTip(
        label: _tapped ? RemoveKey.tapWords : widget.words,
        reveal: _reveal,
        child: Focus(
          onKeyEvent: _key,
          onFocusChange: (focused) {
            setState(() => _focused = focused);
            if (!focused) _hold.cancel();
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() {
              _hovered = false;
              _tapped = false;
            }),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              // a right or middle click is no hold
              onPointerDown: (event) {
                if (event.buttons & kPrimaryButton != 0) _start();
              },
              onPointerUp: (_) => _stop(),
              onPointerCancel: (_) => _hold.cancel(),
              child: AnimatedBuilder(
                animation: _shake,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_swing(_shake.value), 0),
                  child: child,
                ),
                child: CountdownBuilder(
                  countdown: _hold,
                  builder: (context, share, running) {
                    // empty until held, full when the hold is done
                    final fill = _hold.started ? 1 - share : 0.0;
                    final red = running || _hovered || _focused;
                    return FocusRing(
                      on: _focused,
                      corners: Tokens.keyCorners,
                      child: RaisedKey(
                        lit: _hovered,
                        sunk: running,
                        child: SizedBox.square(
                          dimension: Tokens.controlHeight,
                          child: Stack(
                            children: [
                              HoldFill(share: fill),
                              Center(
                                child: AppIcon(
                                  AppIcons.bin,
                                  size: Tokens.iconSize,
                                  color: red ? Tokens.red : Tokens.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fires [RemoveKey]'s tip open after a tap.
class _Signal extends ChangeNotifier {
  void fire() => notifyListeners();
}
