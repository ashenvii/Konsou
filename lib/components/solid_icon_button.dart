import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/icon_def.dart';
import 'hover_mark.dart';
import 'pressable.dart';

/// A square icon button that can turn white with a dark icon, for a control
/// that has to stand out over pictures or a busy page. [solid] runs from 0,
/// on the ground with a soft icon, to 1, white; under the pointer the white
/// dims a step. It always has a drop shadow behind it, so it never blends
/// into a picture.
class SolidIconButton extends StatelessWidget {
  const SolidIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.solid = 1,
  });

  final IconDef icon;
  final String label;
  final VoidCallback onPressed;
  final double solid;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      onPressed: onPressed,
      focusColor: solid > 0.5 ? Tokens.ground : Tokens.ink,
      builder: (context, state) => HoverMark(
        on: state.hovered && solid < 0.5,
        child: Container(
          width: Tokens.controlHeight,
          height: Tokens.controlHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.lerp(
              Tokens.ground,
              state.hovered ? Tokens.inkSoft : Tokens.ink,
              solid,
            ),
            boxShadow: const [
              BoxShadow(
                color: Tokens.shadow,
                blurRadius: Tokens.shadowBlur,
                offset: Offset(0, Tokens.shadowDrop),
              ),
            ],
          ),
          child: AppIcon(
            icon,
            size: Tokens.iconSize,
            color: Color.lerp(
              state.hovered ? Tokens.ink : Tokens.inkSoft,
              Tokens.ground,
              solid,
            )!,
          ),
        ),
      ),
    );
  }
}
