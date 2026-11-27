import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/screens/library/card_details.dart';
import 'package:konsou/components/card_foot.dart';
import 'package:konsou/components/count_display.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/components/cover_image.dart';
import 'package:konsou/components/key_cap.dart';
import 'package:konsou/components/faded.dart';
import 'package:konsou/components/season_cap.dart';
import 'package:konsou/components/skeleton.dart';
import 'package:konsou/components/status_mark.dart';
import 'package:konsou/components/skeleton_lines.dart';
import 'package:konsou/components/row_small_line.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/icons/score_star.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/library/library_view.dart';
import 'package:konsou/screens/library/library_grid_card.dart';
import 'package:konsou/screens/library/library_list_row.dart';
import 'package:konsou/screens/library/list_columns.dart';

import '../../support/render_png.dart';

LibraryRow row({
  String name = 'Frieren',
  String status = 'watching',
  int watched = 4,
  int? episodes = 12,
  int? score = 9,
  int? malId,
  bool hasDetails = true,
  int? seasonsDone,
  int? seasonsTotal,
  int? seasonNumber,
  double? malScore,
  String? mediaType = 'tv',
  String? startDate = '2023-09-29',
  bool isNotAired = false,
}) {
  return LibraryRow(
    current: LibraryEntry(
      entryId: 'a',
      name: name,
      status: EntryStatus.parse(status),
      episodesWatched: watched,
      addedAt: 0,
      changedAt: 0,
      score: score,
      malScore: malScore,
      malId: malId,
      hasDetails: hasDetails,
      episodes: episodes,
      mediaType: mediaType,
      startDate: startDate,
      isNotAired: isNotAired,
    ),
    entryIds: const ['a'],
    addedAt: 0,
    changedAt: 0,
    seasonsDone: seasonsDone,
    seasonsTotal: seasonsTotal,
    seasonNumber: seasonNumber,
  );
}

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  double width = 800,
  bool still = false,
}) {
  if (child is LibraryListRow) child = SizedBox(width: width, child: child);
  return tester.pumpWidget(
    ProviderScope(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 600),
            disableAnimations: still,
          ),
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
}

(String?, String, String?) countOf(WidgetTester tester) {
  final display = tester.widget<CountDisplay>(find.byType(CountDisplay).first);
  return (display.done, display.total, display.unit);
}

void main() {
  group('list row', () {
    Widget listRow(
      LibraryRow row, {
      VoidCallback? onOpen,
      ValueChanged<bool>? onCheck,
      ValueChanged<Offset>? onContextMenu,
    }) => LibraryListRow(
      row: row,
      onOpen: onOpen ?? () {},
      onCheck: onCheck ?? (_) {},
      onContextMenu: onContextMenu ?? (_) {},
      menu: const SizedBox(key: Key('menu'), width: 36, height: 36),
    );

    testWidgets('has the fixed row height and a cover of the token width', (
      tester,
    ) async {
      await pump(tester, listRow(row()));
      expect(
        tester.getSize(find.byType(LibraryListRow)).height,
        Tokens.listRowHeight,
      );
      expect(
        tester.getSize(find.byType(CoverImage)).width,
        Tokens.listCoverWidth,
      );
    });

    testWidgets('the name over its type, then the columns, no labels', (
      tester,
    ) async {
      await pump(tester, listRow(row(malId: 1, malScore: 9.29)));
      expect(find.text('Frieren'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);
      expect(find.byType(StatusMark), findsNothing);
      expect(countOf(tester), ('4', '12', null));
      expect(find.text('9.29'), findsOneWidget);
      expect(find.text('MAL'), findsNothing);
      expect(find.text('Your score'), findsNothing);
      expect(find.byKey(const Key('menu')), findsOneWidget);
    });

    testWidgets('your score sits in its own display', (tester) async {
      await pump(tester, listRow(row(malId: 1, malScore: 9.29)));
      final displays = tester.widgetList<CountDisplay>(
        find.byType(CountDisplay),
      );
      expect(displays.last.total, '9');
      expect(displays.last.done, isNull);
      expect(tester.widget<Text>(find.text('9.29')).style?.color, Tokens.ink);
    });

    testWidgets('no score of yours leaves its place empty', (tester) async {
      await pump(tester, listRow(row(malId: 1, score: null)));
      // the episode display only
      expect(find.byType(CountDisplay), findsOneWidget);
    });

    testWidgets('no score from MAL is a question mark', (tester) async {
      await pump(tester, listRow(row(malId: 1)));
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('a narrow row: the status and MAL join the small line, no '
        'Your score', (tester) async {
      await pump(tester, listRow(row(malId: 1, malScore: 9.29)), width: 360);
      expect(find.text('Watching'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(RowSmallLine),
          matching: find.textContaining('Watching', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(find.text('9.29'), findsNothing);
      expect(find.byType(CountDisplay), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RowSmallLine),
          matching: find.textContaining('9.29', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a franchise counts the episodes of its season, the cap '
        'hung in front without moving the count', (tester) async {
      await pump(tester, listRow(row(malId: 1)));
      final single = tester.getTopLeft(find.byType(CountDisplay).first).dx;
      await pump(
        tester,
        listRow(
          row(malId: 1, seasonsDone: 1, seasonsTotal: 2, seasonNumber: 2),
        ),
      );
      expect(countOf(tester), ('4', '12', null));
      expect(find.text('S2'), findsOneWidget);
      expect(tester.getTopLeft(find.byType(CountDisplay).first).dx, single);
      expect(tester.getRect(find.byType(SeasonCap)).right, lessThan(single));
    });

    testWidgets('no year on the row, aired or not', (tester) async {
      await pump(
        tester,
        listRow(row(malId: 1, startDate: '2027-01-12', isNotAired: true)),
      );
      expect(find.text('TV'), findsOneWidget);
      expect(find.textContaining('2027'), findsNothing);
    });

    testWidgets('the box is checked for Completed, and ticking asks to '
        'complete', (tester) async {
      final ticks = <bool>[];
      await pump(tester, listRow(row(status: 'completed'), onCheck: ticks.add));
      expect(
        tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value,
        CheckValue.checked,
      );
      await tester.tap(find.byType(AppCheckbox));
      expect(ticks, [false]);

      await pump(tester, listRow(row(), onCheck: ticks.add));
      expect(
        tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value,
        CheckValue.empty,
      );
      await tester.tap(find.byType(AppCheckbox));
      expect(ticks, [false, true]);
    });

    testWidgets('a tap opens, the box does not', (tester) async {
      var opened = 0;
      await pump(tester, listRow(row(), onOpen: () => opened++));
      await tester.tap(find.text('Frieren'));
      expect(opened, 1);
      await tester.tap(find.byType(AppCheckbox));
      expect(opened, 1);
    });

    testWidgets('a right click asks for the menu at the pointer', (
      tester,
    ) async {
      final asked = <Offset>[];
      await pump(tester, listRow(row(), onContextMenu: asked.add));
      await tester.tap(find.text('Frieren'), buttons: kSecondaryButton);
      expect(asked, hasLength(1));
    });

    testWidgets('loading details: skeletons for the name and MAL, the count '
        'stays', (tester) async {
      await pump(
        tester,
        listRow(row(name: '', malId: 1, hasDetails: false, episodes: null)),
      );
      expect(find.byType(SkeletonLines), findsOneWidget);
      expect(find.byType(Skeleton), findsWidgets);
      expect(countOf(tester), ('4', '?', null));
    });

    testWidgets('not linked: the saved name, "Not linked", no MAL score', (
      tester,
    ) async {
      await pump(tester, listRow(row(name: 'Saved name')));
      expect(find.text('Saved name'), findsOneWidget);
      expect(find.text('Not linked'), findsOneWidget);
      expect(find.text('?'), findsNothing);
    });

    testWidgets('a long title ends in an ellipsis, not an overflow', (
      tester,
    ) async {
      await pump(
        tester,
        listRow(row(name: 'A very long title ' * 12)),
        width: 360,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('list header bar', () {
    Future<void> pumpList(
      WidgetTester tester, {
      double width = 800,
      ColumnSort? shown,
      ValueChanged<ListColumn>? onPick,
    }) async {
      await loadAppFonts();
      await pump(
        tester,
        SizedBox(
          width: width,
          child: Column(
            children: [
              LibraryListHeader(shown: shown, onPick: onPick ?? (_) {}),
              LibraryListRow(
                row: row(malId: 1, malScore: 9.29),
                onOpen: () {},
                onCheck: (_) {},
                onContextMenu: (_) {},
                menu: const SizedBox(width: 36, height: 36),
              ),
            ],
          ),
        ),
        width: width,
      );
    }

    testWidgets('a tab of one status has no Status column', (tester) async {
      await loadAppFonts();
      await pump(
        tester,
        SizedBox(
          width: 800,
          child: Column(
            children: [
              LibraryListHeader(shown: null, onPick: (_) {}, showStatus: false),
              LibraryListRow(
                row: row(malId: 1, malScore: 9.29),
                showStatus: false,
                onOpen: () {},
                onCheck: (_) {},
                onContextMenu: (_) {},
                menu: const SizedBox(width: 36, height: 36),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Status'), findsNothing);
      expect(find.text('Watching'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Episodes')).dx,
        tester.getTopLeft(find.byType(CountDisplay).first).dx,
      );
    });

    testWidgets('names each column once, over its values', (tester) async {
      await pumpList(tester);
      for (final caption in [
        'Anime name',
        'Status',
        'Episodes',
        'MAL',
        'Your score',
      ]) {
        expect(find.text(caption), findsOneWidget);
      }
      double left(Finder finder) => tester.getTopLeft(finder).dx;
      expect(left(find.text('Anime name')), left(find.text('Frieren')));
      expect(left(find.text('Status')), left(find.text('Watching')));
      expect(
        left(find.text('Episodes')),
        left(find.byType(CountDisplay).first),
      );
      expect(left(find.text('MAL')), left(find.byType(ScoreStar)));
      expect(
        tester.getCenter(find.text('Your score')).dx,
        tester.getCenter(find.byType(CountDisplay).last).dx,
      );
    });

    testWidgets('narrow: Status, MAL and Your score go with their columns', (
      tester,
    ) async {
      await pumpList(tester, width: 360);
      expect(find.text('Status'), findsNothing);
      expect(find.text('MAL'), findsNothing);
      expect(find.text('Your score'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Episodes')).dx,
        tester.getTopLeft(find.byType(CountDisplay).first).dx,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a click on a caption picks its column; Status is no sort', (
      tester,
    ) async {
      final picked = <ListColumn>[];
      await pumpList(tester, onPick: picked.add);
      await tester.tap(find.text('MAL'));
      await tester.tap(find.text('Anime name'));
      await tester.tap(find.text('Status'));
      expect(picked, [ListColumn.mal, ListColumn.name]);
    });

    testWidgets('the sorted column is ink with a pop chevron', (tester) async {
      await pumpList(
        tester,
        shown: (column: ListColumn.episodes, descending: true),
      );
      expect(
        tester.widget<Text>(find.text('Episodes')).style?.color,
        Tokens.ink,
      );
      expect(
        tester.widget<Text>(find.text('MAL')).style?.color,
        Tokens.inkMuted,
      );
      final chevrons = tester
          .widgetList<AppIcon>(find.byType(AppIcon))
          .where((icon) => icon.color == Tokens.pop);
      expect(chevrons, hasLength(1));
    });
  });

  group('grid card', () {
    Widget card(
      LibraryRow row, {
      VoidCallback? onOpen,
      ValueChanged<Offset>? onContextMenu,
    }) => SizedBox(
      width: Tokens.gridCardMinWidth,
      child: LibraryGridCard(
        row: row,
        onOpen: onOpen ?? () {},
        onContextMenu: onContextMenu ?? (_) {},
      ),
    );

    // the real fonts, so the footer measures what fits as the window does
    Future<void> pumpCard(
      WidgetTester tester,
      Widget card, {
      bool still = false,
    }) async {
      await loadAppFonts();
      await pump(tester, card, still: still);
    }

    Future<TestGesture> hover(WidgetTester tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(CoverImage)));
      await tester.pumpAndSettle();
      return mouse;
    }

    final ring = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).border?.top.color == Tokens.pop,
    );

    testWidgets('a cover and a bold name; no type tag, year or MAL score', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1, malScore: 9.29)));
      expect(find.byType(CoverImage), findsOneWidget);
      expect(find.text('Frieren'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Frieren')).style!.fontWeight,
        FontWeight.w600,
      );
      // the panel holds these
      expect(find.byType(KeyCaps), findsNothing);
      expect(find.text('TV'), findsNothing);
      expect(find.text('9.29'), findsNothing);
      expect(find.text('2023'), findsNothing);
    });

    testWidgets('cover, footer and name share one left edge', (tester) async {
      await pumpCard(tester, card(row(malId: 1, malScore: 9.29)));
      final edge = tester.getTopLeft(find.byType(LibraryGridCard)).dx;
      expect(tester.getTopLeft(find.byType(CoverImage)).dx, edge);
      expect(tester.getTopLeft(find.byType(StatusMark)).dx, edge);
      expect(tester.getTopLeft(find.text('Frieren')).dx, edge);
      expect(
        tester.getSize(find.byType(CoverImage)).width,
        Tokens.gridCardMinWidth,
      );
    });

    testWidgets('faded greys the cover; held rings it', (tester) async {
      Widget build({bool faded = false, bool held = false}) => SizedBox(
        width: Tokens.gridCardMinWidth,
        child: LibraryGridCard(
          row: row(malId: 1),
          onOpen: () {},
          onContextMenu: (_) {},
          faded: faded,
          held: held,
        ),
      );
      await pumpCard(tester, build(faded: true));
      expect(tester.widget<Faded>(find.byType(Faded)).on, isTrue);
      expect(ring, findsNothing);
      await pumpCard(tester, build(held: true));
      expect(tester.widget<Faded>(find.byType(Faded)).on, isFalse);
      expect(ring, findsOneWidget);
    });

    testWidgets('the footer sits right under the cover', (tester) async {
      await pumpCard(tester, card(row(malId: 1)));
      final cover = tester.getRect(find.byType(CoverImage));
      final foot = tester.getRect(find.byType(CardFoot));
      expect(foot.top, cover.bottom);
      expect(foot.height, Tokens.cardFootHeight);
    });

    testWidgets('it takes exactly the height the grid sets aside', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1, malScore: 9.29)));
      expect(
        tester.getSize(find.byType(LibraryGridCard)).height,
        closeTo(
          LibraryGridCard.heightFor(
            Tokens.gridCardMinWidth,
            TextScaler.noScaling,
          ),
          0.01,
        ),
      );
    });

    testWidgets('a long name and a short one take the same height', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1)));
      final short = tester.getSize(find.byType(LibraryGridCard)).height;
      await pumpCard(
        tester,
        card(
          row(malId: 1, name: 'Frieren: Beyond Journeys End, a very long name'),
        ),
      );
      expect(tester.getSize(find.byType(LibraryGridCard)).height, short);
    });

    testWidgets('a tab of one status names it, so the card does not', (
      tester,
    ) async {
      await pumpCard(
        tester,
        SizedBox(
          width: Tokens.gridCardMinWidth,
          child: LibraryGridCard(
            row: row(malId: 1),
            showStatus: false,
            onOpen: () {},
            onContextMenu: (_) {},
          ),
        ),
      );
      expect(find.text('Watching'), findsNothing);
      expect(countOf(tester), ('4', '12', null));
    });

    testWidgets('the footer is the status icon and one display', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1)));
      expect(find.byType(StatusMark), findsOneWidget);
      expect(find.text('Watching'), findsNothing);
      expect(countOf(tester), ('4', '12', null));
    });

    testWidgets('a franchise counts the episodes of its season, with its '
        'season cap', (tester) async {
      await pumpCard(
        tester,
        card(row(malId: 1, seasonsDone: 1, seasonsTotal: 2, seasonNumber: 2)),
      );
      expect(countOf(tester), ('4', '12', null));
      expect(find.text('S2'), findsOneWidget);
    });

    testWidgets('hover rings the cover and lifts the card', (tester) async {
      await pumpCard(tester, card(row(malId: 1)));
      final rest = tester.getTopLeft(find.byType(CoverImage));
      expect(ring, findsNothing);
      await hover(tester);
      expect(ring, findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(CoverImage)),
        rest - const Offset(0, Tokens.cardLift),
      );
    });

    testWidgets('under reduced motion hover rings without the lift', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1)), still: true);
      final rest = tester.getTopLeft(find.byType(CoverImage));
      await hover(tester);
      expect(ring, findsOneWidget);
      expect(tester.getTopLeft(find.byType(CoverImage)), rest);
    });

    testWidgets('loading details: skeletons, no tag, the footer stays real', (
      tester,
    ) async {
      await pumpCard(
        tester,
        card(row(name: '', malId: 1, hasDetails: false, episodes: null)),
      );
      expect(find.byType(KeyCaps), findsNothing);
      expect(find.byType(Skeleton), findsWidgets);
      final semantics = tester.ensureSemantics();
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('Loading details')), findsOneWidget);
      semantics.dispose();
      expect(countOf(tester), ('4', '?', null));
    });

    testWidgets('loading takes the same height as a loaded card', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1)));
      final loaded = tester.getSize(find.byType(LibraryGridCard)).height;
      await pumpCard(tester, card(row(name: '', malId: 1, hasDetails: false)));
      expect(tester.getSize(find.byType(LibraryGridCard)).height, loaded);
    });

    testWidgets('not linked: the saved name and the same height; the panel '
        'says it is not linked', (tester) async {
      await pumpCard(tester, card(row(malId: 1)));
      final linked = tester.getSize(find.byType(LibraryGridCard)).height;
      await pumpCard(tester, card(row(name: 'Saved name')));
      expect(find.text('Saved name'), findsOneWidget);
      expect(find.text('Not linked'), findsNothing);
      expect(tester.getSize(find.byType(LibraryGridCard)).height, linked);
      expect(countOf(tester), ('4', '12', null));
    });

    testWidgets('resting on a card opens nothing', (tester) async {
      await pumpCard(tester, card(row(malId: 1)));
      await hover(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CardDetails), findsNothing);
    });

    testWidgets('a tap opens and a right click asks for the menu', (
      tester,
    ) async {
      var opened = 0;
      final asked = <Offset>[];
      await pumpCard(
        tester,
        card(row(malId: 1), onOpen: () => opened++, onContextMenu: asked.add),
      );
      await tester.tap(find.text('Frieren'));
      expect(opened, 1);
      await tester.tap(find.text('Frieren'), buttons: kSecondaryButton);
      expect(asked, hasLength(1));
    });
  });
}
