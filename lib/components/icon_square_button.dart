import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/icon_def.dart';
import 'pressable.dart';
import 'raised_key.dart';

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
    return Pressable(
      label: label,
      onPressed: onPressed,
      selected: selected,
      // a raised key; the selected one (the view showing) stays pressed in
      builder: (context, state) => RaisedKey(
        lit: state.hovered && !selected,
        sunk: selected || state.pressed,
        child: SizedBox.square(
          dimension: Tokens.controlHeight,
          child: Center(
            child: AppIcon(
              icon,
              size: Tokens.iconSize,
              color: selected
                  ? Tokens.pop
                  : (state.hovered ? Tokens.ink : Tokens.inkMuted),
            ),
          ),
        ),
      ),
    );
  }
}
