import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/date_field.dart';
import 'package:konsou/components/entry_progress.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/detail/watch_order.dart';
import 'package:konsou/detail/info_labels.dart';
import 'package:konsou/gallery/detail_section.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/screens/detail/entry_controls.dart';
import 'package:konsou/screens/detail/episode_count.dart';
import 'package:konsou/screens/detail/detail_parts.dart';
import 'package:konsou/screens/detail/jump_bar.dart';
import 'package:konsou/screens/detail/watch_order_strip.dart';

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

  test('a card says the status with its episodes, live ones in mint', () {
    final rows = sampleWatchOrder.rows;
    expect(watchOrderState(rows[0]), ('Watching 4 / 28', true));
    // a finished title says only its episodes
    expect(watchOrderState(rows[1]), ('12 ep', false));
    expect(watchOrderState(rows[2]), ('Not aired yet', false));
    expect(watchOrderState(rows[3]), ('', false));
    const planned = WatchOrderRow(
      malId: 9,
      name: 'x',
      isExtra: false,
      status: EntryStatus.planned,
      episodes: 12,
    );
    expect(watchOrderState(planned), ('Planned · 12 ep', false));
  });

  test('the square is named for a screen reader', () {
    final rows = sampleWatchOrder.rows;
    expect(watchOrderStateLabel(rows[0]), 'Watching');
    expect(watchOrderStateLabel(rows[1]), 'Completed');
    expect(watchOrderStateLabel(rows[2]), 'Not aired yet');
    expect(watchOrderStateLabel(rows[3]), 'Loading details');
  });

  test('a card has its date and type beside its number', () {
    final rows = sampleWatchOrder.rows;
    expect(watchOrderWhen(rows[0]), '2023');
    expect(watchOrderMeta(rows[0]), '2023 · TV');
    // still to air: the whole date
    expect(watchOrderWhen(rows[2]), '16 Jan 2026');
  });

  test('info rows leave out what MAL did not give', () {
    final rows = infoRows(sampleDetails);
    // what the top already shows is not said again
    expect(rows.map((r) => r.$1), isNot(contains('Type')));
    expect(rows.map((r) => r.$1), isNot(contains('Genres')));
    expect(rows.first.$1, 'Aired');
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

  testWidgets('the entry controls show 4 / ? with no total', (tester) async {
    await pumpWidget(
      tester,
      EntryControls(
        statusEntries: const [],
        status: EntryStatus.watching,
        watched: 4,
      ),
    );
    expect(find.text('4'), findsOneWidget);
    expect(find.text(' / ?'), findsOneWidget);
    expect(find.byType(EntryProgress), findsNothing);
  });

  testWidgets('the entry controls off the list offer Add to list', (
    tester,
  ) async {
    await pumpWidget(tester, const EntryControls(statusEntries: []));
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

  group('the synopsis beside the information', () {
    TitleDetails withSynopsis(String synopsis) => TitleDetails(
      malId: sampleDetails.malId,
      name: sampleDetails.name,
      isFull: true,
      fetchedAt: 0,
      mediaType: sampleDetails.mediaType,
      airingStatus: sampleDetails.airingStatus,
      episodes: sampleDetails.episodes,
      startDate: sampleDetails.startDate,
      endDate: sampleDetails.endDate,
      season: sampleDetails.season,
      seasonYear: sampleDetails.seasonYear,
      broadcastDay: sampleDetails.broadcastDay,
      broadcastTime: sampleDetails.broadcastTime,
      secondsPerEpisode: sampleDetails.secondsPerEpisode,
      source: sampleDetails.source,
      rating: sampleDetails.rating,
      studios: sampleDetails.studios,
      genres: sampleDetails.genres,
      synopsis: synopsis,
    );

    Future<void> pumpOverview(WidgetTester tester, String synopsis) async {
      await pumpWidget(
        tester,
        SizedBox(
          width: 1200,
          child: OverviewPart(
            details: withSynopsis(synopsis),
            hidden: false,
            fetching: false,
          ),
        ),
      );
      // the information block is measured after the first frame
      await tester.pump();
    }

    String words(int count) => List.filled(count, 'word').join(' ');

    testWidgets('shows whole while it ends beside the block', (tester) async {
      // about five lines in the test font: past the old four, inside the block
      await pumpOverview(tester, words(45));
      expect(find.text('More'), findsNothing);
    });

    testWidgets('is cut with More once it runs past the block', (tester) async {
      await pumpOverview(tester, words(1500));
      expect(find.text('More'), findsOneWidget);
      final text = find.text(words(1500));
      final block = find
          .ancestor(of: find.text('Airing'), matching: find.byType(ColoredBox))
          .first;
      // the cut text and its More end level with the block, give or take a line
      expect(
        tester.getRect(find.text('More')).bottom,
        lessThanOrEqualTo(tester.getRect(block).bottom + Tokens.text2 * 2),
      );
      expect(tester.getRect(text).height, greaterThan(Tokens.text2 * 8));
    });
  });

  testWidgets('names that do not fit in the jump bar go under More', (
    tester,
  ) async {
    Widget bar(double width) => SizedBox(
      width: width,
      child: JumpBar(
        title: 'Frieren',
        labels: const ['Overview', 'Watch order', 'Stats', 'Recommendations'],
        active: 0,
        stuck: false,
        onJump: (_) {},
        onBack: () {},
        onTop: () {},
      ),
    );
    await pumpWidget(tester, bar(1200));
    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.text('More'), findsNothing);

    await pumpWidget(tester, bar(400));
    expect(find.text('Recommendations'), findsNothing);
    expect(find.text('More'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('the episode count', () {
    Future<List<int>> pumpCount(
      WidgetTester tester, {
      int? total = 500,
      int watched = 4,
    }) async {
      final set = <int>[];
      await pumpWidget(
        tester,
        // the app's WidgetsApp supplies the surface that reports a click
        // outside a field
        TapRegionSurface(
          child: Center(
            child: Column(
              children: [
                EpisodeCount(watched: watched, total: total, onSet: set.add),
                const SizedBox(height: 40, child: Text('elsewhere')),
              ],
            ),
          ),
        ),
      );
      return set;
    }

    Future<void> startEdit(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('Edit the episode count'));
      await tester.pump();
    }

    testWidgets('the pencil opens a field, Enter sets the number', (
      tester,
    ) async {
      final set = await pumpCount(tester);
      expect(find.byType(EditableText), findsNothing);
      await startEdit(tester);
      await tester.enterText(find.byType(EditableText), '256');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(set, [256]);
      expect(find.byType(EditableText), findsNothing);
      expect(find.text(' / 500'), findsOneWidget);
    });

    testWidgets('a click anywhere else sets it too', (tester) async {
      final set = await pumpCount(tester);
      await startEdit(tester);
      await tester.enterText(find.byType(EditableText), '77');
      await tester.tapAt(tester.getCenter(find.text('elsewhere')));
      await tester.pump();
      expect(set, [77]);
    });

    testWidgets('Escape leaves it as it was', (tester) async {
      final set = await pumpCount(tester);
      await startEdit(tester);
      await tester.enterText(find.byType(EditableText), '99');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(set, isEmpty);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('a number past the total is kept at the total', (tester) async {
      final set = await pumpCount(tester);
      await startEdit(tester);
      await tester.enterText(find.byType(EditableText), '900');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(set, [500]);
    });

    testWidgets('letters are not typed, and an empty field changes nothing', (
      tester,
    ) async {
      final set = await pumpCount(tester, total: null);
      await startEdit(tester);
      await tester.enterText(find.byType(EditableText), '1a2');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '12',
      );
      await tester.enterText(find.byType(EditableText), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(set, isEmpty);
      expect(find.text(' / ?'), findsOneWidget);
    });

    testWidgets('an airing show stops at the episodes that have aired', (
      tester,
    ) async {
      var aired = 870;
      final set = <int>[];
      await pumpWidget(
        tester,
        TapRegionSurface(
          child: EpisodeCount(
            watched: 4,
            total: null,
            onSet: set.add,
            limit: () => aired,
          ),
        ),
      );
      Future<void> typeIn(String text) async {
        await tester.tap(find.bySemanticsLabel('Edit the episode count'));
        await tester.pump();
        await tester.enterText(find.byType(EditableText), text);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
      }

      await typeIn('900');
      expect(set, [870]);
      // a new episode airs
      aired = 871;
      await typeIn('900');
      expect(set, [870, 871]);
    });

    testWidgets('a count already past the limit is not pulled down', (
      tester,
    ) async {
      final set = <int>[];
      await pumpWidget(
        tester,
        TapRegionSurface(
          child: EpisodeCount(
            watched: 9,
            total: null,
            onSet: set.add,
            limit: () => 8,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Edit the episode count'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), '12');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(set, isEmpty);
    });
  });
}
