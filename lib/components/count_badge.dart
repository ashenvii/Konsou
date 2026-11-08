import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';

/// A small mint count. Anything above 99 reads 99+. [onAccent] is for a
/// badge on an amber fill, where mint would vanish: it turns dark with a
/// mint number.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.onAccent = false});

  final int count;
  final bool onAccent;

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
          color: onAccent ? Tokens.ground : Tokens.mint,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space1),
            child: Center(
              widthFactor: 1,
              // The badge is a fixed 16 tall, so its digits do not scale with
              // the system text size.
              child: Text(
                text,
                textScaler: TextScaler.noScaling,
                style: AppText.count(onAccent ? Tokens.mint : Tokens.ground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
