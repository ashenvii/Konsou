import 'dart:math';

import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/score_star.dart';
import '../library/row_labels.dart';
import 'one_line_text.dart';

/// The gold star and MAL's score in ink, "?" where MAL has none: the line
/// under a card's name, and the score in a list row or the quick panel at
/// [size]. A score with no room is cut with an ellipsis.
class MalScoreLine extends StatelessWidget {
  const MalScoreLine({
    super.key,
    required this.score,
    this.size = Tokens.text1,
  });

  final double? score;
  final double size;

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
          Flexible(
            child: OneLineText(
              score,
              style: AppText.tally(Tokens.ink, size: size),
            ),
          ),
        ],
      ),
    );
  }
}
