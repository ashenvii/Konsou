import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'measure_text.dart';
import 'skeleton.dart';

/// A card's name: two lines at most, cut with an ellipsis, and always the
/// height of two lines so the lines under it meet across a row of cards.
/// [loading] draws a skeleton bar in its place.
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

  static TextStyle _styleFor(Color color) => AppText.label(
    color,
    bold: true,
  ).copyWith(height: Tokens.lineHeightWrapped);

  /// The height it always takes, for a grid that sizes its cells ahead.
  static double heightFor(TextScaler textScaler) => measureText(
    '\n',
    _styleFor(Tokens.ink),
    textScaler: textScaler,
    maxLines: 2,
  ).height;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(color);
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // two empty lines hold the room at any text size
          Text('\n', maxLines: 2, style: style),
          if (loading)
            Semantics(
              label: 'Loading details',
              child: const FractionallySizedBox(
                widthFactor: 0.8,
                child: Skeleton(height: Tokens.text2),
              ),
            )
          else
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
        ],
      ),
    );
  }
}
