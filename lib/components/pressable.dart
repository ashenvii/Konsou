import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// What a pressable is doing right now, handed to the builder.
class PressState {
  const PressState({required this.hovered, required this.focused});

  final bool hovered;
  final bool focused;
}

/// The one place that handles mouse, keyboard and focus for anything you can
/// press. Buttons, tabs and checkboxes are built on it. A null [onPressed]
/// means disabled.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.selected,
    this.checked,
    this.autofocus = false,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, PressState state) builder;
  final bool? selected;
  final bool? checked;
  final bool autofocus;

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
      PressState(hovered: _hovered, focused: _focused),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      checked: widget.checked,
      child: FocusableActionDetector(
        enabled: enabled,
        autofocus: widget.autofocus,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
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
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: _focused
                    ? Border.all(color: Tokens.ink, width: Tokens.focusRing)
                    : null,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
