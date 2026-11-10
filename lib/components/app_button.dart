import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'count_badge.dart';
import 'menu_chevron.dart';
import 'pressable.dart';

enum ButtonKind { primary, secondary }

/// Amber primary or plain secondary button. A null [onPressed] disables it.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.primary,
    this.opensMenu = false,
    this.count,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;

  /// Shows a chevron after the label, for a button that opens a menu.
  final bool opensMenu;

  /// A count badge at the end, such as the number of entries a choice holds.
  final int? count;

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(ink, bold: primary && enabled),
                ),
              ),
              if (opensMenu) MenuChevron(color: ink),
              if (count != null) ...[
                const SizedBox(width: Tokens.space2),
                CountBadge(count!, onAccent: primary && enabled),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
