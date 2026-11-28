import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'one_line_text.dart';
import 'row_small_line.dart';

/// A row's name over its small line, as Library list rows and Quick search
/// rows show them. [withScore] and [malScore] go to the [RowSmallLine].
class RowTitles extends StatelessWidget {
  const RowTitles({
    super.key,
    required this.name,
    required this.line,
    this.nameColor = Tokens.ink,
    this.withScore = false,
    this.malScore,
  });

  final String name;
  final String line;
  final Color nameColor;
  final bool withScore;
  final double? malScore;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OneLineText(name, style: AppText.label(nameColor)),
      const SizedBox(height: Tokens.space2),
      RowSmallLine(line, withScore: withScore, malScore: malScore),
    ],
  );
}
