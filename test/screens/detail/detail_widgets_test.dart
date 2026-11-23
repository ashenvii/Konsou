import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/date_field.dart';
import 'package:konsou/components/entry_progress.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/detail/info_labels.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/gallery/detail_section.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/screens/detail/entry_controls.dart';
import 'package:konsou/screens/detail/episode_count.dart';
import 'package:konsou/screens/detail/jump_bar.dart';
import 'package:konsou/screens/detail/overview_part.dart';

import '../../support/pump_widget.dart';

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

  test('info rows leave out what MAL did not give', () {
    final rows = listInfoRows(sampleDetails);
    // what the top already shows is not said again
    expect(rows.map((r) => r.$1), isNot(contains('Type')));
    expect(rows.map((r) => r.$1), isNot(contains('Genres')));
    expect(rows.first.$1, 'Aired');
    expect(rows.map((r) => r.$1), contains('Broadcast'));
    expect(
      rows.firstWhere((r) => r.$1 == 'Broadcast').$2,
      'Fridays at 23:00 JST',
    );
    expect(formatMalDate('2023'), '2023');
    expect(formatMalDate('2023-09'), 'Sep 2023');
    expect(formatMalDate(null), isNull);
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

  testWidgets('a new segment lights over a moment, not at once', (
    tester,
  ) async {
    Widget progress(int watched) => Center(
      child: SizedBox(
        width: 300,
        child: EntryProgress(watched: watched, total: 10, onStep: (_) {}),
      ),
    );
    await pumpWidget(tester, progress(1));
    expect(tester.hasRunningAnimations, isFalse);
    await pumpWidget(tester, progress(2));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump();
    await tester.pump(Tokens.motionSegment ~/ 2);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(Tokens.motionSegment * 2);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'minus and plus sit together right of the bar, the count under it',
    (tester) async {
      await pumpWidget(
        tester,
        SizedBox(
          width: 700,
          child: EntryControls(
            statusEntries: const [],
            status: EntryStatus.watching,
            watched: 4,
            total: 12,
            onMinus: () {},
            onPlus: () {},
            onStep: (_) {},
          ),
        ),
      );
      final bar = tester.getRect(find.byType(EntryProgress));
      final minus = tester.getRect(find.bySemanticsLabel('One episode less'));
      final plus = tester.getRect(find.bySemanticsLabel('One episode more'));
      final count = tester.getRect(find.byKey(const Key('episode-display')));
      expect(minus.left, greaterThan(bar.right));
      expect(plus.left - minus.right, closeTo(Tokens.space1, 1));
      expect(count.top, greaterThan(bar.bottom));
      expect(count.top - minus.bottom, closeTo(Tokens.space2, 1));
      // the count and its pencil together sit under the middle of the bar
      final pencil = tester.getRect(
        find.bySemanticsLabel('Edit the episode count'),
      );
      expect((count.left + pencil.right) / 2, closeTo(bar.center.dx, 1));
    },
  );

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
    Widget bar(double width, {int active = 0}) => SizedBox(
      width: width,
      child: JumpBar(
        title: 'Frieren',
        labels: const ['Overview', 'Watch order', 'Stats', 'Recommendations'],
        active: active,
        stuck: false,
        onJump: (_) {},
        onBack: () {},
        onTop: () {},
      ),
    );
    await pumpWidget(tester, bar(1200));
    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.text('More'), findsNothing);

    await pumpWidget(tester, bar(520));
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Recommendations'), findsNothing);
    expect(find.text('More'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the More tab has room for the active name it shows', (
    tester,
  ) async {
    const labels = ['Overview', 'Watch order', 'Stats', 'Recommendations'];
    await pumpWidget(
      tester,
      SizedBox(
        width: 520,
        child: JumpBar(
          title: 'Frieren',
          labels: labels,
          active: 3,
          stuck: false,
          onJump: (_) {},
          onBack: () {},
          onTop: () {},
        ),
      ),
    );
    final barBox = tester.getRect(find.byType(JumpBar));
    final shown = tester.getRect(find.text('Recommendations'));
    expect(find.text('More'), findsNothing);
    expect(shown.right, lessThanOrEqualTo(barBox.right));
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
