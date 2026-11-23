import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/score_star.dart';

/// A score as the Detail page shows one: a star and the number large
/// and bright, over its [label] in muted ink. With no [value] the star is
/// grey and [empty] stands in; a score the user can set says so instead,
/// with a small star and a pop [empty] such as "Rate", so it never weighs
/// as much as a real score. [lit] brightens it under the pointer.
class ScoreFigure extends StatelessWidget {
  const ScoreFigure({
    super.key,
    required this.value,
    required this.empty,
    required this.label,
    this.lit = false,
    this.settable = false,
    this.starColor = Tokens.pop,
  });

  final String? value;
  final String empty;
  final String label;
  final bool lit;
  final bool settable;

  /// The star's colour: the user's own score uses pop, MyAnimeList's the
  /// ordinary star gold.
  final Color starColor;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScoreStar(
              size: value == null && settable ? Tokens.text3 : Tokens.text4,
              color: value == null ? Tokens.inkMuted : starColor,
            ),
            const SizedBox(width: Tokens.space2),
            Text(
              value ?? empty,
              style: switch ((value, settable)) {
                (null, true) => AppText.label(
                  lit ? Tokens.ink : Tokens.pop,
                  bold: true,
                ),
                (null, false) => AppText.caption(Tokens.inkMuted),
                // the user's own score is lit, like an LED display
                _ when settable => AppText.led(Tokens.pop, size: Tokens.text5),
                _ => AppText.tally(Tokens.ink, size: Tokens.text5),
              },
            ),
          ],
        ),
        const SizedBox(height: Tokens.space2),
        Text(
          label,
          style: AppText.caption(lit ? Tokens.inkSoft : Tokens.inkMuted),
        ),
      ],
    );
  }
}
