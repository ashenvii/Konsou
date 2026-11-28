import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'cap_centered_text.dart';
import 'hold_fill.dart';

/// Label of the row that removes on hold.
const holdToRemoveLabel = 'Hold to remove';

/// Hint under the hold to remove row.
const holdToRemoveHint = 'Hold for a second. It cannot be undone.';

/// A menu row that runs [onDone] once held for [holdTime].
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

class _HoldRowState extends State<HoldRow> with HoldPress {
  @override
  Duration get holdTime => widget.holdTime;

  @override
  void holdDone() => widget.onDone?.call();

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
        onKeyEvent: enabled ? holdKey : null,
        onFocusChange: focusChanged,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: enabled ? holdPointer : null,
            onPointerUp: enabled ? (_) => stopHold() : null,
            onPointerCancel: enabled ? (_) => hold.cancel() : null,
            child: Padding(
              padding: const EdgeInsets.all(Tokens.space3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // only as wide as the bin and the words; the slab hangs below
                  Padding(
                    padding: const EdgeInsets.only(bottom: Tokens.buttonDepth),
                    child: HoldKey(
                      press: this,
                      lit: hovered && enabled,
                      face: (_) => SizedBox(
                        height: Tokens.controlHeight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox.square(
                              dimension: Tokens.controlHeight,
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
