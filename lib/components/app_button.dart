import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'pressable.dart';

enum ButtonKind { primary, secondary }

/// Amber primary or plain secondary button. A null [onPressed] disables it.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final primary = kind == ButtonKind.primary;
    final fill = primary && enabled ? Tokens.amber : Tokens.surface;
    final ink = !enabled
        ? Tokens.inkMuted
        : (primary ? Tokens.ground : Tokens.ink);
    return Pressable(
      onPressed: onPressed,
      focusColor: primary && enabled ? Tokens.ground : Tokens.ink,
      builder: (context, state) => Container(
        height: Tokens.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: Tokens.space4),
        color: fill,
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(ink, bold: primary && enabled),
          ),
        ),
      ),
    );
  }
}
