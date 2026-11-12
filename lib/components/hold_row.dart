import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'countdown.dart';

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
    Widget label(Color color) => Center(
      child: Text(
        widget.label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: AppText.label(color, bold: true),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // a button of its own: red outline, filling red as it is held
                  DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _focused ? Tokens.ink : Tokens.red,
                        width: Tokens.checkboxBorder,
                      ),
                    ),
                    child: ColoredBox(
                      color: _hovered || _focused
                          ? Tokens.ground
                          : Tokens.surface,
                      child: SizedBox(
                        height: Tokens.controlHeight,
                        child: CountdownBuilder(
                          countdown: _hold,
                          builder: (context, share, running) {
                            // empty until held, full when the hold is done
                            final fill = _hold.started ? 1 - share : 0.0;
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: fill,
                                    child: const ColoredBox(color: Tokens.red),
                                  ),
                                ),
                                // the label sizes the row
                                label(Tokens.red),
                                // the same label in dark ink over the filled part
                                Positioned.fill(
                                  child: ClipRect(
                                    clipper: _LeftShare(fill),
                                    child: label(Tokens.ground),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
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

class _LeftShare extends CustomClipper<Rect> {
  _LeftShare(this.share);

  final double share;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * share, size.height);

  @override
  bool shouldReclip(_LeftShare oldClipper) => oldClipper.share != share;
}
