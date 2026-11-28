import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'focus_ring.dart';
import 'touch_target.dart';

/// Whether a pressable is hovered, focused or pressed, for its builder.
class PressState {
  const PressState({
    required this.hovered,
    required this.focused,
    this.pressed = false,
  });

  final bool hovered;
  final bool focused;
  final bool pressed;
}

/// The base of every pressable thing: hover, focus, press, keys, semantics.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.label,
    this.selected,
    this.checked,
    this.expanded,
    this.autofocus = false,
    this.cursor = SystemMouseCursors.click,
    this.focusColor = Tokens.ink,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, PressState state) builder;

  final String? label;
  final bool? selected;
  final bool? checked;

  /// For a control that opens a menu: whether the menu is showing.
  final bool? expanded;
  final bool autofocus;

  final MouseCursor cursor;

  final Color focusColor;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

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
      PressState(
        hovered: _hovered && enabled,
        focused: _focused,
        pressed: _pressed && enabled,
      ),
    );
    return Semantics(
      button: true,
      label: widget.label,
      enabled: enabled,
      selected: widget.selected,
      checked: widget.checked,
      expanded: widget.expanded,
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
            // none when disabled, or it would read as something to tap
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            child: TouchTarget(
              child: FocusRing(
                on: _focused,
                color: widget.focusColor,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
