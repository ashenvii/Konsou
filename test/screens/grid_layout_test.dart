import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/cover_image.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/screens/library/grid_layout.dart';

void main() {
  test('as many columns as fit at the minimum card width and the gap', () {
    // 5 cards of 168 with 4 gaps of 16 is 904
    final layout = GridLayout.forWidth(904);
    expect(layout.columns, 5);
    expect(layout.cardWidth, 168);
  });

  test(
    'cards share what is left over, so none is narrower than the minimum',
    () {
      final layout = GridLayout.forWidth(1000);
      expect(layout.columns, 5);
      expect(layout.cardWidth, greaterThan(Tokens.gridCardMinWidth));
      expect(
        layout.cardWidth * layout.columns +
            Tokens.space4 * (layout.columns - 1),
        closeTo(1000, 0.001),
      );
    },
  );

  test('a narrow window still gets one column, full width', () {
    final layout = GridLayout.forWidth(120);
    expect(layout.columns, 1);
    expect(layout.cardWidth, 120);
  });

  test('a phone gets two columns', () {
    expect(GridLayout.forWidth(360 - 2 * Tokens.space4).columns, 1);
    expect(
      GridLayout.forWidth(2 * Tokens.gridCardMinWidth + Tokens.space4).columns,
      2,
    );
  });

  test('the card is tall enough for its cover and two lines of text', () {
    final layout = GridLayout.forWidth(904);
    expect(layout.cardHeight, greaterThan(CoverImage.heightFor(168)));
  });
}
