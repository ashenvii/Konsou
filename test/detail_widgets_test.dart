import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/date_field.dart';
import 'package:konsou/components/entry_progress.dart';
import 'package:konsou/detail/info_labels.dart';
import 'package:konsou/gallery/detail_section.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/screens/detail/back_bar.dart';
import 'package:konsou/screens/detail/entry_bar.dart';
import 'package:konsou/screens/detail/watch_order_row.dart';

import 'support/pump_widget.dart';

void main() {
  test('progress draws steps by episode count, fewer on a narrow window', () {
    // a wide window: up to 24 steps, never one per episode of a long show
    expect(EntryProgress.drawsSteps(1200, 24), isTrue);
    expect(EntryProgress.drawsSteps(1200, 25), isFalse);
    expect(EntryProgress.drawsSteps(1200, 170), isFalse);
    // a narrow one: up to 12
    expect(EntryProgress.drawsSteps(479, 12), isTrue);
    expect(EntryProgress.drawsSteps(479, 13), isFalse);
    expect(EntryProgress.drawsSteps(480, 24), isTrue);
    expect(EntryProgress.drawsSteps(1200, 0), isFalse);
  });

  test('the watch order summary counts the list and the episodes', () {
    expect(
      watchOrderSummary(sampleWatchOrder),
      '2 of 4 on your list · 16 of 40 episodes watched',
    );
  });

  test('info rows leave out what MAL did not give', () {
    final rows = infoRows(sampleDetails);
    expect(rows.first, ('Type', 'TV'));
    expect(rows.map((r) => r.$1), contains('Broadcast'));
    expect(
      rows.firstWhere((r) => r.$1 == 'Broadcast').$2,
      'Fridays at 23:00 JST',
    );
    expect(dateWords('2023'), '2023');
    expect(dateWords('2023-09'), 'Sep 2023');
    expect(dateWords(null), isNull);
  });

  testWidgets('a step click sets the count', (tester) async {
    int? set;
    await pumpWidget(
      tester,
      Center(
        child: SizedBox(
          width: 300,
          child: EntryProgress(watched: 1, total: 10, onStep: (n) => set = n),
        ),
      ),
    );
    final box = tester.getTopLeft(find.byType(EntryProgress));
    await tester.tapAt(box + const Offset(75, 4));
    expect(set, 3);
  });

  testWidgets('the entry bar shows 4 / ? with no total', (tester) async {
    await pumpWidget(
      tester,
      EntryBar(
        statusEntries: const [],
        status: EntryStatus.watching,
        watched: 4,
      ),
    );
    expect(find.text('4 / ?'), findsOneWidget);
    expect(find.byType(EntryProgress), findsNothing);
  });

  testWidgets('the entry bar off the list offers Add to list', (tester) async {
    await pumpWidget(tester, const EntryBar(statusEntries: []));
    expect(find.text('Add to list'), findsOneWidget);
  });

  testWidgets('the date field picks a day and clears it', (tester) async {
    DateTime? value = DateTime(2023, 10, 6);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: StatefulBuilder(
                    builder: (context, setState) => DateField(
                      value: value,
                      onChanged: (v) => setState(() => value = v),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('6 Oct 2023'), findsOneWidget);
    await tester.tap(find.text('6 Oct 2023'));
    await tester.pump();
    await tester.tap(find.text('15'));
    await tester.pump();
    expect(value, DateTime(2023, 10, 15));
    await tester.tap(find.text('15 Oct 2023'));
    await tester.pump();
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(value, isNull);
  });

  testWidgets('the back bar shows the title only once scrolled', (
    tester,
  ) async {
    Widget bar(bool scrolled) => BackBar(
      title: 'Frieren',
      scrolled: scrolled,
      onBack: () {},
      onTitle: () {},
    );
    await pumpWidget(tester, bar(false));
    expect(find.text('Frieren'), findsNothing);
    await pumpWidget(tester, bar(true));
    expect(find.text('Frieren'), findsOneWidget);
  });
}
