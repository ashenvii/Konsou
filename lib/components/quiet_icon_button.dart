import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/icon_def.dart';
import 'icon_cell.dart';
import 'pressable.dart';

/// A small icon with no fill that brightens on hover: the three dots at the end
/// of a row, the X on a toast. [label] is what a screen reader says.
class QuietIconButton extends StatelessWidget {
  const QuietIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconDef icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      onPressed: onPressed,
      builder: (context, state) => IconCell(
        icon: icon,
        size: Tokens.iconSize,
        color: state.hovered ? Tokens.ink : Tokens.inkMuted,
      ),
    );
  }
}
