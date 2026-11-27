import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/score_star.dart';
import '../library/row_labels.dart';

/// The small line under a row's name: "TV · 2023" (the Library list gives the
/// type alone). In a narrow row, where the MAL column has no room, MAL's
/// score joins it: "TV · ★ 9.29". One
/// line of text, so on a very small row it ends in an ellipsis like the name.
class RowSmallLine extends StatelessWidget {
  const RowSmallLine(
    this.text, {
    super.key,
    this.withScore = false,
    this.malScore,
  });

  final String text;
  final bool withScore;
  final double? malScore;

  @override
  Widget build(BuildContext context) {
    final style = AppText.caption(Tokens.inkMuted);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text),
          if (withScore) ...[
            if (text.isNotEmpty) const TextSpan(text: ' · '),
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: ScoreStar(size: Tokens.text1, color: Tokens.star),
            ),
            TextSpan(
              text: ' ${formatMalScore(malScore)}',
              style: AppText.tally(Tokens.ink, size: Tokens.text1),
            ),
          ],
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }
}
