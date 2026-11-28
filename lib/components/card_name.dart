import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'held_lines.dart';
import 'measure_text.dart';

/// A card's name: two lines at most, cut with an ellipsis, and always the
/// height of two lines so the lines under it meet across a row of cards.
/// [loading] shows its loading bars.
class CardName extends StatelessWidget {
  const CardName(
    this.name, {
    super.key,
    this.color = Tokens.ink,
    this.loading = false,
  });

  final String name;
  final Color color;
  final bool loading;

  static TextStyle _styleFor(Color color) =>
      AppText.label(color, bold: true).wrapped;

  /// The height it always takes, for a grid that sizes its cells ahead.
  static double heightFor(TextScaler textScaler) => measureText(
    '\n',
    _styleFor(Tokens.ink),
    textScaler: textScaler,
    maxLines: 2,
  ).height;

  @override
  Widget build(BuildContext context) =>
      HeldLines(name, lines: 2, style: _styleFor(color), loading: loading);
}
