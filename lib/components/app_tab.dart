import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'count_badge.dart';
import 'pressable.dart';

/// One tab. The selected tab is a filled amber block. Put tabs side by side in
/// a Row; the padding gives the gap.
class AppTab extends StatelessWidget {
  const AppTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      selected: selected,
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
              Text(label, style: AppText.label(ink)),
              if (count != null) ...[
                const SizedBox(width: Tokens.space2),
                CountBadge(count!),
              ],
            ],
          ),
        );
      },
    );
  }
}
