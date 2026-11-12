import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/icon_def.dart';
import 'hover_mark.dart';
import 'icon_cell.dart';
import 'pressable.dart';

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
      builder: (context, state) => HoverMark(
        on: state.hovered,
        child: IconCell(
          icon: icon,
          size: Tokens.iconSize,
          color: selected
              ? Tokens.amber
              : (state.hovered ? Tokens.ink : Tokens.inkMuted),
        ),
      ),
    );
  }
}
