import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'cap_centered.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'countdown.dart';
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

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter &&
        event.logicalKey != LogicalKeyboardKey.space) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) _start();
    if (event is KeyUpEvent) _stop();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
      child: CapCentered(
        style: AppText.label(Tokens.red, bold: true),
        child: Text(
          widget.label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(Tokens.red, bold: true),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: widget.label,
      hint: widget.hint,
      child: Focus(
        onKeyEvent: _key,
        onFocusChange: (focused) {
          setState(() => _focused = focused);
          if (!focused) _stop();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _start(),
            onPointerUp: (_) => _stop(),
            onPointerCancel: (_) => _stop(),
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
                        return DecoratedBox(
                          position: DecorationPosition.foreground,
                          decoration: BoxDecoration(
                            borderRadius: Tokens.keyCorners,
                            border: _focused
                                ? Border.all(
                                    color: Tokens.ink,
                                    width: Tokens.checkboxBorder,
                                  )
                                : null,
                          ),
                          child: RaisedKey(
                            lit: _hovered,
                            sunk: _hold.started,
                            child: SizedBox(
                              height: Tokens.controlHeight,
                              child: Stack(
                                children: [
                                  // the hold rises through the key from the foot
                                  Positioned.fill(
                                    child: FractionallySizedBox(
                                      alignment: Alignment.bottomCenter,
                                      heightFactor: fill,
                                      child: ColoredBox(
                                        color: Tokens.red.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                  ),
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

