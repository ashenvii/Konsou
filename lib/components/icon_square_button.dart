import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/icon_def.dart';
import 'pressable.dart';

/// A square button holding one icon. Selected is amber with a dark icon; the
/// rest sit on the surface color. [label] is what a screen reader says.
class IconSquareButton extends StatelessWidget {
  const IconSquareButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconDef icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Pressable(
        onPressed: onPressed,
        selected: selected,
        focusColor: selected ? Tokens.ground : Tokens.ink,
        builder: (context, state) => ColoredBox(
          color: selected ? Tokens.amber : Tokens.surface,
          child: SizedBox.square(
            dimension: Tokens.controlHeight,
            child: Center(
              child: AppIcon(
                icon,
                size: Tokens.railIconSize,
                color: selected
                    ? Tokens.ground
                    : (state.hovered ? Tokens.ink : Tokens.inkMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
