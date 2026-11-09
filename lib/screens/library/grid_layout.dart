import 'dart:math';

import '../../components/cover_image.dart';
import '../../design/tokens.dart';

/// How many cards fit across the Library's grid and how big each one is: as
/// many as fit at the minimum card width with a gap between, sharing the
/// leftover width.
class GridLayout {
  const GridLayout({
    required this.columns,
    required this.cardWidth,
    required this.cardHeight,
  });

  final int columns;
  final double cardWidth;
  final double cardHeight;

  static const gap = Tokens.space4;

  factory GridLayout.forWidth(double width) {
    final columns = max(
      1,
      ((width + gap) / (Tokens.gridCardMinWidth + gap)).floor(),
    );
    final cardWidth = (width - gap * (columns - 1)) / columns;
    // cover, then the title and the small line under it
    final cardHeight =
        CoverImage.heightFor(cardWidth) +
        Tokens.space2 +
        Tokens.text3 +
        Tokens.space1 +
        Tokens.text2;
    return GridLayout(
      columns: columns,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
    );
  }
}
