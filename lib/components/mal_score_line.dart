import 'dart:math';

import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/score_star.dart';
import '../library/row_labels.dart';

/// The line under a card's name: the gold star, MAL's score in ink, then a dot
/// and [when] (`formatCardWhen`). The strip card leaves [when] out.
class MalScoreLine extends StatelessWidget {
  const MalScoreLine({super.key, required this.score, this.when});

  final double? score;
  final String? when;

  /// Its texts are one font size tall, the star a fixed one.
  static double heightFor(TextScaler textScaler) =>
      max(Tokens.text1, textScaler.scale(Tokens.text1));

  @override
  Widget build(BuildContext context) {
    final score = formatMalScore(this.score);
    final when = this.when;
    final muted = AppText.caption(Tokens.inkMuted);
    return Semantics(
      label: 'MAL score $score${when == null ? '' : ', $when'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ScoreStar(size: Tokens.text1, color: Tokens.star),
          const SizedBox(width: Tokens.space1),
          Text(score, style: AppText.tally(Tokens.ink, size: Tokens.text1)),
          if (when != null) ...[
            const SizedBox(width: Tokens.space1),
            Text('·', style: muted),
            const SizedBox(width: Tokens.space1),
            Flexible(
              child: Text(
                when,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
