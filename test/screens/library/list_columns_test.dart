import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/screens/library/list_columns.dart';

void main() {
  const scales = [1.0, 1.25, 1.5, 2.0];

  test('a wide row always leaves the name a card width', () {
    for (final scale in scales) {
      final textScaler = TextScaler.linear(scale);
      for (var width = 300.0; width <= 2000; width++) {
        if (ListColumns.isNarrow(width, textScaler)) continue;
        expect(
          width - ListColumns.besideName(textScaler),
          greaterThanOrEqualTo(Tokens.gridCardMinWidth),
          reason: '$width wide at ${scale}x',
        );
      }
    }
  });

  test('the row goes narrow the moment the name would drop below a card', () {
    for (final scale in scales) {
      final textScaler = TextScaler.linear(scale);
      final edge = ListColumns.besideName(textScaler) + Tokens.gridCardMinWidth;
      expect(ListColumns.isNarrow(edge, textScaler), isFalse);
      expect(ListColumns.isNarrow(edge - 1, textScaler), isTrue);
    }
  });

  test('larger text moves the switch to a wider row', () {
    final small = ListColumns.besideName(const TextScaler.linear(1));
    final large = ListColumns.besideName(const TextScaler.linear(1.5));
    expect(large, greaterThan(small));
  });
}
