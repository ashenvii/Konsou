import 'dart:math';

import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/score_star.dart';
import '../library/row_labels.dart';

/// The line under a card's name: the gold star and MAL's score in ink, "?"
/// where MAL has none.
class MalScoreLine extends StatelessWidget {
  const MalScoreLine({super.key, required this.score});

  final double? score;

  /// Its texts are one font size tall, the star a fixed one.
  static double heightFor(TextScaler textScaler) =>
      max(Tokens.text1, textScaler.scale(Tokens.text1));

  @override
  Widget build(BuildContext context) {
    final score = formatMalScore(this.score);
    return Semantics(
      label: 'MAL score $score',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ScoreStar(size: Tokens.text1, color: Tokens.star),
          const SizedBox(width: Tokens.space1),
          Text(score, style: AppText.tally(Tokens.ink, size: Tokens.text1)),
        ],
      ),
    );
  }
}
