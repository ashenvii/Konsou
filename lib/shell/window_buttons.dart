import 'package:flutter/widgets.dart';

import '../components/pressable.dart';
import '../components/raised_key.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../icons/icon_def.dart';

enum WindowGlyph { minimize, maximize, restore, close }

/// One of the three window buttons, drawn like every other app button: a
/// raised key with an icon from the library. The slot keeps the size Windows
/// is told about, so snap layouts still line up. Close turns red on hover.
/// Built on [Pressable], so the keyboard reaches it and it has a spoken name.
class WindowButton extends StatelessWidget {
  const WindowButton({
    super.key,
    required this.glyph,
    required this.onPressed,
    this.hovered = false,
    this.pressed = false,
  });

  final WindowGlyph glyph;
  final VoidCallback onPressed;

  // the maximize button's pointer belongs to Windows, which reports it here
  final bool hovered;
  final bool pressed;

  String get _label => switch (glyph) {
    WindowGlyph.minimize => 'Minimize',
    WindowGlyph.maximize => 'Maximize',
    WindowGlyph.restore => 'Restore',
    WindowGlyph.close => 'Close',
  };

  IconDef get _icon => switch (glyph) {
    WindowGlyph.minimize => AppIcons.minimize,
    WindowGlyph.maximize => AppIcons.maximize,
    WindowGlyph.restore => AppIcons.restore,
    WindowGlyph.close => AppIcons.close,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _label,
      child: Pressable(
        onPressed: onPressed,
        cursor: SystemMouseCursors.basic,
        builder: (context, state) {
          final held = state.pressed || pressed;
          final over = state.hovered || hovered;
          final color = !over && !held
              ? Tokens.inkMuted
              : (glyph == WindowGlyph.close ? Tokens.red : Tokens.ink);
          return SizedBox(
            width: Tokens.windowButtonWidth,
            height: Tokens.barHeight,
            child: Center(
              child: SizedBox(
                width: Tokens.windowKeyWidth,
                height: Tokens.windowKeyHeight,
                child: RaisedKey(
                  lit: over && !held,
                  sunk: held,
                  child: Center(
                    child: AppIcon(_icon, size: Tokens.iconSize, color: color),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
