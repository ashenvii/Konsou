import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../components/cover_image.dart';
import '../../design/text_styles.dart';
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
    // cover, then the title and the small line under it
    final cardHeight =
        CoverImage.heightFor(cardWidth) +
        Tokens.space2 +
        _lineHeight(AppText.label(Tokens.ink, bold: true), textScaler) +
        Tokens.space1 +
        _lineHeight(AppText.caption(Tokens.inkMuted), textScaler);
    return GridLayout(
      columns: columns,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
    );
  }

  static double _lineHeight(TextStyle style, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }
}
