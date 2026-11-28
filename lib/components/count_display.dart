import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../library/row_labels.dart';
import 'sunk_decoration.dart';

/// A number pair in one sunk display, "4 / 12", like the Detail page's
/// episode display but with no glow. The slash and a unit ("ep", "seasons")
/// are muted. With no [done] it shows the [total] alone: "12 ep". With
/// [digits] both numbers take that many places, [done] to the right of its
/// own and [total] to the left, so a column of displays keeps its slashes in
/// one place.
class CountDisplay extends StatelessWidget {
  const CountDisplay({
    super.key,
    required this.total,
    this.done,
    this.unit,
    this.digits,
  });

  /// A card's or row's count (`countCard`).
  factory CountDisplay.of(CardCount count, {Key? key, int? digits}) =>
      CountDisplay(
        key: key,
        done: count.done,
        total: count.total,
        unit: count.unit,
        digits: digits,
      );

  final String? done;
  final String total;
  final String? unit;
  final int? digits;

  @override
  Widget build(BuildContext context) {
    final done = this.done;
    final unit = this.unit;
    final ink = AppText.tally(Tokens.ink, size: Tokens.text2);
    final muted = AppText.tally(Tokens.inkMuted, size: Tokens.text2);
    final small = AppText.tally(Tokens.inkMuted, size: Tokens.text1);
    final spoken = switch ((done, unit)) {
      (null, null) => total,
      (null, final unit?) => '$total $unit',
      (final done?, null) => '$done of $total episodes',
      (final done?, final unit?) => '$done of $total $unit',
    };
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: sunkDisplay,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.space1,
            vertical: Tokens.displayInset,
          ),
          child: Text.rich(
            TextSpan(
              children: [
                if (done != null) ...[
                  TextSpan(text: done.padLeft(digits ?? 0), style: ink),
                  TextSpan(text: ' / ', style: muted),
                ],
                TextSpan(text: total.padRight(digits ?? 0), style: ink),
                if (unit != null) TextSpan(text: ' $unit', style: small),
              ],
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}
