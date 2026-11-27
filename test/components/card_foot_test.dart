import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/card_foot.dart';
import 'package:konsou/components/count_display.dart';
import 'package:konsou/components/season_cap.dart';
import 'package:konsou/components/status_mark.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/row_labels.dart';

import '../support/pump_widget.dart';
import '../support/render_png.dart';

void main() {
  // the real fonts, so what fits is measured as the window draws it
  Future<void> pumpFoot(
    WidgetTester tester,
    CardFoot foot, {
    double width = Tokens.gridCardMinWidth,
  }) async {
    await loadAppFonts();
    await pumpWidget(tester, SizedBox(width: width, child: foot));
  }

  String spoken(WidgetTester tester) =>
      tester.getSemantics(find.byType(CountDisplay)).label;

  testWidgets('it is the footer height', (tester) async {
    await pumpFoot(
      tester,
      CardFoot(count: countCard(onList: false, total: 12)),
    );
    expect(tester.getSize(find.byType(CardFoot)).height, Tokens.cardFootHeight);
  });

  testWidgets('the status icon at the left, one display at the right', (
    tester,
  ) async {
    await pumpFoot(
      tester,
      CardFoot(
        status: EntryStatus.watching,
        count: countCard(onList: true, watched: 9, total: 28),
      ),
    );
    final foot = tester.getRect(find.byType(CardFoot));
    expect(tester.getTopLeft(find.byType(StatusMark)).dx, foot.left);
    expect(find.text('Watching'), findsNothing);
    expect(find.bySemanticsLabel('Watching'), findsOneWidget);
    expect(tester.getTopRight(find.byType(CountDisplay)).dx, foot.right);
    expect(find.byType(CountDisplay), findsOneWidget);
    expect(spoken(tester), '9 of 28 episodes');
  });

  testWidgets('the numbers are 16, plain ink, no glow', (tester) async {
    await pumpFoot(
      tester,
      CardFoot(
        status: EntryStatus.watching,
        count: countCard(onList: true, watched: 9, total: 28),
      ),
    );
    final text = tester.widget<RichText>(
      find.descendant(
        of: find.byType(CountDisplay),
        matching: find.byType(RichText),
      ),
    );
    TextSpan? first;
    text.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        first = span;
        return false;
      }
      return true;
    });
    expect(first!.text, '9');
    expect(first!.style?.fontSize, Tokens.text2);
    expect(first!.style?.color, Tokens.ink);
    expect(first!.style?.shadows, isNull);
  });

  testWidgets('not on your list: no word, the total in episodes', (
    tester,
  ) async {
    await pumpFoot(
      tester,
      CardFoot(count: countCard(onList: false, total: 12)),
    );
    expect(spoken(tester), '12 ep');
  });

  testWidgets('no total from MAL reads "?"', (tester) async {
    await pumpFoot(
      tester,
      CardFoot(status: EntryStatus.planned, count: countCard(onList: true)),
    );
    expect(spoken(tester), '0 of ? episodes');
  });

  testWidgets('a franchise puts its season cap in front of the count', (
    tester,
  ) async {
    await pumpFoot(
      tester,
      CardFoot(
        status: EntryStatus.watching,
        count: countCard(onList: true, watched: 3, total: 12),
        season: 2,
      ),
    );
    expect(spoken(tester), '3 of 12 episodes');
    expect(find.text('S2'), findsOneWidget);
    expect(
      tester.getRect(find.byType(SeasonCap)).right,
      lessThan(tester.getRect(find.byType(CountDisplay)).left),
    );
  });

  testWidgets('long counts stay whole, never overflow', (tester) async {
    await pumpFoot(
      tester,
      CardFoot(
        status: EntryStatus.notInterested,
        count: countCard(onList: true, watched: 1071, total: 1100),
      ),
      width: Tokens.gridCardMinWidth - Tokens.space5,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byType(CountDisplay)).right,
      lessThanOrEqualTo(tester.getRect(find.byType(CardFoot)).right),
    );
  });
}
