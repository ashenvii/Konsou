import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../design/tokens.dart';
import 'library_grid_card.dart';

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

  // closer across than down, so a row of covers reads as one line
  static const columnGap = Tokens.space3;
  static const rowGap = Tokens.space5;

  SliverGridDelegate get delegate => SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: rowGap,
    crossAxisSpacing: columnGap,
    mainAxisExtent: cardHeight,
  );

  factory GridLayout.forWidth(double width, {required TextScaler textScaler}) {
    final columns = max(
      1,
      ((width + columnGap) / (Tokens.gridCardMinWidth + columnGap)).floor(),
    );
    final cardWidth = (width - columnGap * (columns - 1)) / columns;
    final cardHeight = LibraryGridCard.heightFor(cardWidth, textScaler);
    return GridLayout(
      columns: columns,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
    );
  }
}
