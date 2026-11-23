import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'menu_chevron.dart';
import 'pressable.dart';
import 'weight_text.dart';

/// One tab: a word with a lit pop underline when selected and its count in LED
/// digits beside it, pop and glowing on the selected tab. Put tabs side by side
/// in a Row; the padding gives the gap.
class AppTab extends StatelessWidget {
  const AppTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.count,
    this.opensMenu = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final int? count;

  /// Shows a chevron after the label, for a tab that opens a menu.
  final bool opensMenu;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      selected: selected,
      builder: (context, state) {
        final ink = selected || state.hovered ? Tokens.ink : Tokens.inkMuted;
        return Container(
          height: Tokens.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space4),
          foregroundDecoration: selected
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Tokens.pop,
                      width: Tokens.hoverEdge,
                    ),
                  ),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: WeightText(label, color: ink, bold: selected),
              ),
              if (opensMenu) MenuChevron(color: ink),
              if (count != null) ...[
                const SizedBox(width: Tokens.space2),
                Text(
                  '$count',
                  maxLines: 1,
                  softWrap: false,
                  style: selected
                      ? AppText.led(Tokens.pop, size: Tokens.text1)
                      : AppText.tally(Tokens.inkMuted, size: Tokens.text1),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
