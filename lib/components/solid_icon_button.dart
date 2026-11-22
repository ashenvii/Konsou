import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/icon_def.dart';
import 'pressable.dart';
import 'raised_key.dart';

/// The look of a white key: white with a dark face, dimming a step under the
/// pointer, over a muted slab and a drop shadow so it never blends into a
/// picture. Shared by [SolidIconButton] and the Detail bar's title key.
BoxDecoration solidKeyDecoration({required bool hovered}) => BoxDecoration(
  color: hovered ? Tokens.inkSoft : Tokens.ink,
  borderRadius: Tokens.keyCorners,
  boxShadow: const [
    BoxShadow(color: Tokens.inkMuted, offset: Offset(0, Tokens.buttonDepth)),
    BoxShadow(
      color: Tokens.shadow,
      blurRadius: Tokens.shadowBlur,
      offset: Offset(0, Tokens.shadowDrop),
    ),
  ],
);

/// A square white icon key with a dark icon, for a control that has to stand
/// out over pictures or a busy page.
class SolidIconButton extends StatelessWidget {
  const SolidIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconDef icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      onPressed: onPressed,
      focusColor: Tokens.ground,
      builder: (context, state) => Transform.translate(
        offset: keyLift,
        child: Container(
          width: Tokens.controlHeight,
          height: Tokens.controlHeight,
          alignment: Alignment.center,
          decoration: solidKeyDecoration(hovered: state.hovered),
          child: AppIcon(icon, size: Tokens.iconSize, color: Tokens.ground),
        ),
      ),
    );
  }
}
