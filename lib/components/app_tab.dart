import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'count_badge.dart';
import 'menu_chevron.dart';
import 'pressable.dart';
import 'weight_text.dart';

/// One tab. The selected tab is a filled amber block. Put tabs side by side in
/// a Row; the padding gives the gap.
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
      focusColor: selected ? Tokens.ground : Tokens.ink,
      builder: (context, state) {
        final ink = selected
            ? Tokens.ground
            : (state.hovered ? Tokens.ink : Tokens.inkMuted);
        return Container(
          height: Tokens.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space4),
          color: selected ? Tokens.amber : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: WeightText(label, color: ink, bold: selected),
              ),
              if (opensMenu) MenuChevron(color: ink),
              if (count != null) ...[
                const SizedBox(width: Tokens.space2),
                CountBadge(count!, onAccent: selected),
              ],
            ],
          ),
        );
      },
    );
  }
}
