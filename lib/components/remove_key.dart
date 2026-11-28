import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'hold_fill.dart';
import 'hold_row.dart';
import 'hover_tip.dart';

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

  @override
  State<RemoveKey> createState() => _RemoveKeyState();
}

class _RemoveKeyState extends State<RemoveKey> with HoldPress {
  var _tapped = false;

  @override
  Duration get holdTime => widget.holdTime;

  @override
  void holdDone() => widget.onDone();

  @override
  void startHold() {
    setState(() => _tapped = false);
    super.startHold();
  }

  // let go before the hold was done: show how it works
  @override
  void letGoEarly() => setState(() => _tapped = true);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.words,
      onLongPress: widget.onDone,
      child: HoverTip(
        label: _tapped ? holdToRemoveLabel : widget.words,
        reveal: early,
        child: Focus(
          onKeyEvent: holdKey,
          onFocusChange: focusChanged,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hovered = true),
            onExit: (_) => setState(() {
              hovered = false;
              _tapped = false;
            }),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: holdPointer,
              onPointerUp: (_) => stopHold(),
              onPointerCancel: (_) => hold.cancel(),
              child: HoldKey(
                press: this,
                lit: hovered,
                face: (running) => SizedBox.square(
                  dimension: Tokens.controlHeight,
                  child: Center(
                    child: AppIcon(
                      AppIcons.bin,
                      size: Tokens.iconSize,
                      color: running || hovered || focused
                          ? Tokens.red
                          : Tokens.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
