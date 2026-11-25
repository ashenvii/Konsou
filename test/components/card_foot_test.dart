import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/card_foot.dart';
import 'package:konsou/components/status_lamp.dart';
import 'package:konsou/components/status_mark.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/library/entry_status.dart';

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

  Color? countColor(WidgetTester tester, String count) =>
      tester.widget<Text>(find.text(count)).style?.color;

  testWidgets('it is the footer height', (tester) async {
    await pumpFoot(tester, const CardFoot(count: '12 ep'));
    expect(tester.getSize(find.byType(CardFoot)).height, Tokens.cardFootHeight);
  });

  testWidgets('the count sits at the right edge', (tester) async {
    await pumpFoot(
      tester,
      const CardFoot(status: EntryStatus.watching, count: '9 / 28'),
    );
    expect(
      tester.getTopRight(find.text('9 / 28')).dx,
      tester.getTopRight(find.byType(CardFoot)).dx - Tokens.space1,
    );
    expect(
      tester.getTopLeft(find.text('9 / 28')).dx,
      greaterThan(tester.getTopRight(find.byType(StatusLamp)).dx),
    );
  });

  testWidgets('a title not on your list has no lamp, no mark, soft count', (
    tester,
  ) async {
    await pumpFoot(tester, const CardFoot(count: 'Ep 8 / 12', showMark: true));
    expect(find.byType(StatusLamp), findsNothing);
    expect(find.byType(StatusMark), findsNothing);
    expect(countColor(tester, 'Ep 8 / 12'), Tokens.inkSoft);
  });

  testWidgets('watching lights the count, any other status is ink', (
    tester,
  ) async {
    await pumpFoot(
      tester,
      const CardFoot(status: EntryStatus.watching, count: '9 / 28'),
    );
    final lit = tester.widget<Text>(find.text('9 / 28')).style!;
    expect(lit.color, Tokens.pop);
    expect(lit.shadows, isNotEmpty);

    await pumpFoot(
      tester,
      const CardFoot(status: EntryStatus.onHold, count: '3 / 12'),
    );
    expect(countColor(tester, '3 / 12'), Tokens.ink);
  });

  testWidgets('the mark shows only on a tab that mixes statuses', (
    tester,
  ) async {
    await pumpFoot(
      tester,
      const CardFoot(status: EntryStatus.planned, count: '0 / ?'),
    );
    expect(find.byType(StatusLamp), findsOneWidget);
    expect(find.byType(StatusMark), findsNothing);

    await pumpFoot(
      tester,
      const CardFoot(
        status: EntryStatus.planned,
        count: '0 / ?',
        showMark: true,
      ),
    );
    expect(find.byType(StatusMark), findsOneWidget);
  });

  testWidgets('the status word shows on hover where it fits', (tester) async {
    await pumpFoot(
      tester,
      const CardFoot(status: EntryStatus.watching, count: '9 / 28'),
    );
    expect(find.text('Watching'), findsNothing);

    await pumpFoot(
      tester,
      const CardFoot(
        status: EntryStatus.watching,
        count: '9 / 28',
        showMark: true,
        showWord: true,
      ),
    );
    expect(find.text('Watching'), findsOneWidget);
  });

  testWidgets('with no room the word goes and the count stays whole', (
    tester,
  ) async {
    await pumpFoot(
      tester,
      const CardFoot(
        status: EntryStatus.notInterested,
        count: '12 / 24 seasons',
        showMark: true,
        showWord: true,
      ),
      width: 150,
    );
    expect(find.text('Not interested'), findsNothing);
    expect(find.text('12 / 24 seasons'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with less room still the mark goes, then the lamp', (
    tester,
  ) async {
    const foot = CardFoot(
      status: EntryStatus.completed,
      count: '12 / 24 seasons',
      showMark: true,
    );
    await pumpFoot(tester, foot, width: 130);
    expect(find.byType(StatusMark), findsNothing);
    expect(find.byType(StatusLamp), findsOneWidget);

    await pumpFoot(tester, foot, width: 110);
    expect(find.byType(StatusLamp), findsNothing);
    expect(find.text('12 / 24 seasons'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a completed franchise with a season left stays unlit', (
    tester,
  ) async {
    await pumpFoot(
      tester,
      const CardFoot(
        status: EntryStatus.completed,
        finished: false,
        count: '1 / 2 seasons',
        showMark: true,
      ),
    );
    expect(tester.widget<StatusLamp>(find.byType(StatusLamp)).finished, false);
    expect(tester.widget<StatusMark>(find.byType(StatusMark)).green, false);
  });
}
