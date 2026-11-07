import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';

/// A small mint count. Anything above 99 reads 99+.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Semantics(
      label: '$count',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: Tokens.badgeSize,
          minHeight: Tokens.badgeSize,
          maxHeight: Tokens.badgeSize,
        ),
        child: ColoredBox(
          color: Tokens.mint,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space1),
            child: Center(
              widthFactor: 1,
              child: Text(text, style: AppText.count(Tokens.ground)),
            ),
          ),
        ),
      ),
    );
  }
}
