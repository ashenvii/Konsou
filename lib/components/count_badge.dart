import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';

/// A small teal count, always the real number; the badge grows to fit it.
/// [onAccent] is for a badge on a cyan fill, where teal would vanish: it
/// turns dark with a teal number.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.onAccent = false});

  final int count;
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    final text = '$count';
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
          color: onAccent ? Tokens.ground : Tokens.support,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space1),
            child: Center(
              widthFactor: 1,
              // The badge is a fixed 16 tall, so its digits do not scale with
              // the system text size.
              child: Text(
                text,
                textScaler: TextScaler.noScaling,
                style: AppText.count(onAccent ? Tokens.support : Tokens.ground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
