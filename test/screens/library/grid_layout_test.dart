import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/cover_image.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/screens/library/grid_layout.dart';

void main() {
  test('as many columns as fit at the minimum card width and the gap', () {
    // 5 cards of 168 with 4 gaps of 12 is 888
    final layout = GridLayout.forWidth(888, textScaler: TextScaler.noScaling);
    expect(layout.columns, 5);
    expect(layout.cardWidth, 168);
  });

  test(
    'cards share what is left over, so none is narrower than the minimum',
    () {
      final layout = GridLayout.forWidth(
        1000,
        textScaler: TextScaler.noScaling,
      );
      expect(layout.columns, 5);
      expect(layout.cardWidth, greaterThan(Tokens.gridCardMinWidth));
      expect(
        layout.cardWidth * layout.columns +
            GridLayout.columnGap * (layout.columns - 1),
        closeTo(1000, 0.001),
      );
    },
  );

  test('a narrow window still gets one column, full width', () {
    final layout = GridLayout.forWidth(120, textScaler: TextScaler.noScaling);
    expect(layout.columns, 1);
    expect(layout.cardWidth, 120);
  });

  test('a phone gets one column, two need two minimum widths and a gap', () {
    expect(
      GridLayout.forWidth(
        360 - 2 * Tokens.space4,
        textScaler: TextScaler.noScaling,
      ).columns,
      1,
    );
    expect(
      GridLayout.forWidth(
        2 * Tokens.gridCardMinWidth + GridLayout.columnGap,
        textScaler: TextScaler.noScaling,
      ).columns,
      2,
    );
  });

  test('the card is tall enough for its cover and two lines of text', () {
    final layout = GridLayout.forWidth(904, textScaler: TextScaler.noScaling);
    expect(layout.cardHeight, greaterThan(CoverImage.heightFor(168)));
  });
}
