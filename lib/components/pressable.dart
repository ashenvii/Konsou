import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'touch_target.dart';

class PressState {
  const PressState({required this.hovered, required this.focused});

  final bool hovered;
  final bool focused;
}

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.label,
    this.selected,
    this.checked,
    this.autofocus = false,
    this.cursor = SystemMouseCursors.click,
    this.focusColor = Tokens.ink,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, PressState state) builder;

  final String? label;
  final bool? selected;
  final bool? checked;
  final bool autofocus;

  final MouseCursor cursor;

  final Color focusColor;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _focused = false;

  static const _activate = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final child = widget.builder(
      context,
      // A disabled control does not light up under the pointer.
      PressState(hovered: _hovered && enabled, focused: _focused),
    );
    return Semantics(
      button: true,
      label: widget.label,
      enabled: enabled,
      selected: widget.selected,
      checked: widget.checked,
      child: FocusableActionDetector(
        enabled: enabled,
        autofocus: widget.autofocus,
        mouseCursor: enabled ? widget.cursor : SystemMouseCursors.basic,
        shortcuts: _activate,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: TouchTarget(
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: _focused
                      ? Border.all(
                          color: widget.focusColor,
                          width: Tokens.focusRing,
                        )
                      : null,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
