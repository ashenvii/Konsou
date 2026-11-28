import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/score_star.dart';
import '../library/row_labels.dart';
import 'one_line_text.dart';
import 'skeleton_lines.dart';
import 'value_column.dart';

/// A row's MAL column: MAL's score over the gold star and "MAL", "?" where
/// MAL has none. [loading] holds a skeleton where the score goes; [blank]
/// (a title with no MAL page) leaves it empty.
class MalColumn extends StatelessWidget {
  const MalColumn({
    super.key,
    required this.score,
    this.loading = false,
    this.blank = false,
  });

  static const width = Tokens.space5 * 2 + Tokens.space4;

  final double? score;
  final bool loading;
  final bool blank;

  @override
  Widget build(BuildContext context) {
    final style = AppText.tally(Tokens.ink, size: Tokens.text2);
    final Widget value;
    if (loading) {
      value = const SkeletonLine();
    } else {
      // a blank keeps the line's height so the label stays put
      value = Opacity(
        opacity: blank ? 0 : 1,
        child: OneLineText(formatMalScore(score), style: style),
      );
    }
    return ValueColumn(
      width: width,
      value: value,
      label: Row(
        children: [
          const ScoreStar(size: Tokens.text1, color: Tokens.star),
          const SizedBox(width: Tokens.space1),
          Text('MAL', style: AppText.caption(Tokens.inkMuted)),
        ],
      ),
    );
  }
}
