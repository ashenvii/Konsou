import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'pressable.dart';

/// The three dots at the end of a row. It only draws and reports a press; the
/// screen puts a popover around it.
class MoreButton extends StatelessWidget {
  const MoreButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'More',
      child: Pressable(
        onPressed: onPressed,
        builder: (context, state) => SizedBox.square(
          dimension: Tokens.controlHeight,
          child: Center(
            child: AppIcon(
              AppIcons.more,
              size: Tokens.iconSize,
              color: state.hovered ? Tokens.ink : Tokens.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
