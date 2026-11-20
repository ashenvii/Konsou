import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/solid_icon_button.dart';
import 'package:konsou/components/peek_row.dart';
import 'package:konsou/design/tokens.dart';

import '../support/pump_widget.dart';

void main() {
  group('the layout at every width', () {
    const gap = Tokens.space3;

    // every page width from the smallest window to a 4K screen, at the
    // narrowest items normal, 125% and 150% text could ask for
    for (final minItem in [112.0, 140.0, 198.0]) {
      test('items no narrower than $minItem, the sliver always its share', () {
        for (var width = 300.0; width <= 3800; width += 1) {
          final layout = PeekLayout.fit(
            width: width,
            minItem: minItem,
            gap: gap,
            count: 100,
          );
          expect(layout.itemWidth, greaterThanOrEqualTo(minItem - 1e-9));
          final used = layout.whole * layout.step;
          final sliver = width - used;
          expect(
            sliver,
            closeTo(Tokens.peekShare * layout.itemWidth, 1e-6),
            reason: 'width $width',
          );
          // one more whole item would not have fit
          expect(
            (layout.whole + 1) * (minItem + gap) + Tokens.peekShare * minItem,
            greaterThan(width),
            reason: 'width $width',
          );
        }
      });
    }

    test('a few titles fit whole with nothing to peek at', () {
      final layout = PeekLayout.fit(
        width: 1500,
        minItem: 112,
        gap: gap,
        count: 3,
      );
      expect(layout.fitsAll, isTrue);
      expect(layout.lastFirst, 0);
    });

    test('the last page ends on whole items', () {
      final layout = PeekLayout.fit(
        width: 880,
        minItem: 112,
        gap: gap,
        count: 10,
      );
      expect(layout.clampFirst(99), 10 - layout.whole);
      expect(layout.clampFirst(-3), 0);
    });

    test('showing an item moves as little as it can', () {
      final layout = PeekLayout.fit(
        width: 880,
        minItem: 112,
        gap: gap,
        count: 20,
      );
      final whole = layout.whole;
      expect(layout.firstShowing(2, 0), 0);
      expect(layout.firstShowing(whole, 0), 1);
      expect(layout.firstShowing(3, 5), 3);
    });

    test('too narrow for one item and its sliver keeps the item whole', () {
      final layout = PeekLayout.fit(
        width: 100,
        minItem: 112,
        gap: gap,
        count: 5,
      );
      expect(layout.whole, 1);
      expect(layout.itemWidth, 100);
    });
  });

  group('the row', () {
    Widget row(int count, {int startAt = 0}) => PeekRow(
      count: count,
      startAt: startAt,
      minItemWidth: 112,
      arrowTop: (width) => 0,
      itemBuilder: (context, i, width) =>
          SizedBox(height: 40, child: Text('item $i')),
    );

    Finder arrow(String label) =>
        find.byWidgetPredicate((w) => w is SolidIconButton && w.label == label);

    testWidgets('only the right arrow shows at the start', (tester) async {
      await pumpWidget(tester, SizedBox(width: 880, child: row(20)));
      expect(arrow('Later titles'), findsOneWidget);
      expect(arrow('Earlier titles'), findsNothing);
    });

    testWidgets('the right arrow moves the peeking item to first place', (
      tester,
    ) async {
      await pumpWidget(tester, SizedBox(width: 880, child: row(20)));
      final layout = PeekLayout.fit(
        width: 880,
        minItem: 112,
        gap: Tokens.space3,
        count: 20,
      );
      final peeking = 'item ${layout.whole}';
      await tester.tap(arrow('Later titles'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text(peeking)).dx,
        closeTo(tester.getTopLeft(find.byType(PeekRow)).dx, 0.5),
      );
      expect(arrow('Earlier titles'), findsOneWidget);
    });

    testWidgets('no arrows when everything fits', (tester) async {
      await pumpWidget(tester, SizedBox(width: 880, child: row(3)));
      expect(arrow('Later titles'), findsNothing);
      expect(arrow('Earlier titles'), findsNothing);
    });
    testWidgets('it can start with a later item on screen', (tester) async {
      await pumpWidget(
        tester,
        SizedBox(width: 880, child: row(20, startAt: 15)),
      );
      final left = tester.getTopLeft(find.byType(PeekRow)).dx;
      final x = tester.getTopLeft(find.text('item 15')).dx;
      expect(x, inInclusiveRange(left, left + 880));
      expect(arrow('Earlier titles'), findsOneWidget);
    });
  });
}
