import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'cap_centered_text.dart';
import 'countdown.dart';
import 'countdown_builder.dart';
import 'focus_ring.dart';
import 'hold_fill.dart';
import 'raised_key.dart';

const holdToRemoveLabel = 'Hold to remove';
const holdToRemoveHint = 'Hold for a second. It cannot be undone.';

class HoldRow extends StatefulWidget {
  const HoldRow({
    super.key,
    required this.label,
    required this.holdTime,
    required this.onDone,
    this.hint,
  });

  final String label;
  final Duration holdTime;
  final VoidCallback? onDone;

  final String? hint;

  @override
  State<HoldRow> createState() => _HoldRowState();
}

class _HoldRowState extends State<HoldRow> {
  late final Countdown _hold = Countdown(onDone: () => widget.onDone?.call());
  var _hovered = false;
  var _focused = false;

  void _start() => _hold.start(widget.holdTime);

  void _stop() => _hold.cancel();

  KeyEventResult _key(FocusNode node, KeyEvent event) =>
      holdOnKeys(event, start: _start, stop: _stop);

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onDone != null;
    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
      child: CapCenteredText(
        widget.label,
        style: AppText.label(Tokens.red, bold: true),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      hint: widget.hint,
      onLongPress: widget.onDone,
      child: Focus(
        canRequestFocus: enabled,
        skipTraversal: !enabled,
        onKeyEvent: enabled ? _key : null,
        onFocusChange: (focused) {
          setState(() => _focused = focused);
          if (!focused) _stop();
        },
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: enabled ? (_) => _start() : null,
            onPointerUp: enabled ? (_) => _stop() : null,
            onPointerCancel: enabled ? (_) => _stop() : null,
            child: Padding(
              padding: const EdgeInsets.all(Tokens.space3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // only as wide as the bin and the words; the slab hangs below
                  Padding(
                    padding: const EdgeInsets.only(bottom: Tokens.buttonDepth),
                    child: CountdownBuilder(
                      countdown: _hold,
                      builder: (context, share, running) {
                        // empty until held, full when the hold is done
                        final fill = _hold.started ? 1 - share : 0.0;
                        return FocusRing(
                          on: _focused,
                          corners: Tokens.keyCorners,
                          child: RaisedKey(
                            lit: _hovered && enabled,
                            sunk: _hold.started,
                            child: SizedBox(
                              height: Tokens.controlHeight,
                              child: Stack(
                                children: [
                                  HoldFill(share: fill),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: Tokens.controlHeight,
                                        height: Tokens.controlHeight,
                                        child: ColoredBox(
                                          color: Tokens.red,
                                          child: Center(
                                            child: AppIcon(
                                              AppIcons.bin,
                                              size: Tokens.iconSize,
                                              color: Tokens.onPop,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Flexible(child: label),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (widget.hint != null) ...[
                    const SizedBox(height: Tokens.space2),
                    Text(widget.hint!, style: AppText.caption(Tokens.inkSoft)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
