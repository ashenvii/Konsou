import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/screens/library/card_details.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/components/touch_target.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/components/card_foot.dart';
import 'package:konsou/components/cover_well.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/components/cover_image.dart';
import 'package:konsou/components/key_cap.dart';
import 'package:konsou/components/mal_score_line.dart';
import 'package:konsou/components/skeleton.dart';
import 'package:konsou/components/status_lamp.dart';
import 'package:konsou/components/status_mark.dart';
import 'package:konsou/components/value_column.dart';
import 'package:konsou/components/skeleton_lines.dart';
import 'package:konsou/components/row_small_line.dart';
import 'package:konsou/components/mal_column.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/screens/library/library_grid_card.dart';
import 'package:konsou/screens/library/library_list_row.dart';

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

void main() {
  group('list row', () {
    Widget listRow(
      LibraryRow row, {
      bool showStatus = false,
      VoidCallback? onOpen,
      ValueChanged<bool>? onCheck,
      ValueChanged<Offset>? onContextMenu,
    }) => LibraryListRow(
      row: row,
      showStatus: showStatus,
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

    testWidgets('the name over its type and year, then the columns', (
      tester,
    ) async {
      await pump(tester, listRow(row(malId: 1, malScore: 9.29)));
      expect(find.text('Frieren'), findsOneWidget);
      expect(find.text('TV · 2023'), findsOneWidget);
      expect(find.text('4 / 12'), findsOneWidget);
      expect(find.text('9.29'), findsOneWidget);
      expect(find.text('MAL'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('Your score'), findsOneWidget);
      expect(find.byKey(const Key('menu')), findsOneWidget);
    });

    testWidgets('your score is the pop LED, MAL\'s is ink', (tester) async {
      await pump(tester, listRow(row(malId: 1, malScore: 9.29)));
      expect(tester.widget<Text>(find.text('9')).style?.color, Tokens.pop);
      expect(tester.widget<Text>(find.text('9.29')).style?.color, Tokens.ink);
    });

    testWidgets('the Your score column is as wide as its label', (
      tester,
    ) async {
      await pump(tester, listRow(row(malId: 1)));
      final column = find.ancestor(
        of: find.text('Your score'),
        matching: find.byType(ValueColumn),
      );
      expect(
        tester.getSize(column).width,
        tester.getSize(find.text('Your score')).width.ceilToDouble(),
      );
    });

    testWidgets('no score of yours leaves its place empty', (tester) async {
      await pump(tester, listRow(row(malId: 1, score: null)));
      expect(find.text('Your score'), findsOneWidget);
      expect(find.text('9'), findsNothing);
    });

    testWidgets('no score from MAL is a question mark', (tester) async {
      await pump(tester, listRow(row(malId: 1)));
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('on a mixed tab the episode column names the status', (
      tester,
    ) async {
      await pump(tester, listRow(row(malId: 1), showStatus: true));
      expect(find.text('Watching'), findsOneWidget);
      expect(find.byType(StatusLamp), findsOneWidget);
    });

    testWidgets('on a tab of one status the lamp stands alone', (tester) async {
      await pump(tester, listRow(row(malId: 1)));
      expect(find.text('Watching'), findsNothing);
      expect(find.byType(StatusMark), findsNothing);
      expect(find.byType(StatusLamp), findsOneWidget);
    });

    testWidgets('a narrow row: the mark for the word, MAL in the small line, '
        'no Your score', (tester) async {
      await pump(
        tester,
        listRow(row(malId: 1, malScore: 9.29), showStatus: true),
        width: 360,
      );
      expect(find.text('Watching'), findsNothing);
      expect(find.byType(StatusMark), findsOneWidget);
      expect(find.byType(MalColumn), findsNothing);
      expect(find.text('Your score'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(RowSmallLine),
          matching: find.textContaining('9.29', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a franchise counts its seasons', (tester) async {
      await pump(
        tester,
        listRow(row(malId: 1, seasonsDone: 1, seasonsTotal: 2)),
      );
      expect(find.text('1 / 2 seasons'), findsOneWidget);
      expect(find.text('TV · 2023'), findsOneWidget);
    });

    testWidgets('a title not aired yet gives its whole date', (tester) async {
      await pump(
        tester,
        listRow(row(malId: 1, startDate: '2027-01-12', isNotAired: true)),
      );
      expect(find.text('TV · 12 Jan 2027'), findsOneWidget);
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
      expect(
        find.descendant(
          of: find.byType(MalColumn),
          matching: find.byType(Skeleton),
        ),
        findsOneWidget,
      );
      expect(find.text('?'), findsNothing);
      expect(find.text('4 / ?'), findsOneWidget);
    });

    testWidgets('not linked: the saved name, "Not linked", no MAL score', (
      tester,
    ) async {
      await pump(tester, listRow(row(name: 'Saved name')));
      expect(find.text('Saved name'), findsOneWidget);
      expect(find.text('Not linked'), findsOneWidget);
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: find.text('?'), matching: find.byType(Opacity)),
            )
            .opacity,
        0,
      );
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

  group('grid card', () {
    Widget card(
      LibraryRow row, {
      bool showStatus = false,
      VoidCallback? onOpen,
      ValueChanged<Offset>? onContextMenu,
    }) => SizedBox(
      width: Tokens.gridCardMinWidth,
      child: LibraryGridCard(
        row: row,
        showStatus: showStatus,
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
      await mouse.moveTo(tester.getCenter(find.byType(CoverWell)));
      await tester.pumpAndSettle();
      return mouse;
    }

    testWidgets('a cover, the type tag, a bold name and the score line', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1, malScore: 9.29)));
      expect(find.byType(CoverImage), findsOneWidget);
      expect(find.byType(KeyCaps), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
      expect(find.text('Frieren'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Frieren')).style!.fontWeight,
        FontWeight.w600,
      );
      expect(find.text('9.29'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
      expect(find.byKey(const Key('card-chip')), findsNothing);
    });

    testWidgets('no score from MAL is a question mark', (tester) async {
      await pumpCard(tester, card(row(malId: 1)));
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('a title not aired yet gives its whole date', (tester) async {
      await pumpCard(
        tester,
        card(row(malId: 1, startDate: '2027-01-12', isNotAired: true)),
      );
      expect(find.text('12 Jan 2027'), findsOneWidget);
    });

    testWidgets('the cover fills the card width inside its well', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1)));
      expect(
        tester.getSize(find.byType(CoverImage)).width,
        Tokens.gridCardMinWidth - CoverWell.inset,
      );
    });

    testWidgets('the footer sits in the well under the cover', (tester) async {
      await pumpCard(tester, card(row(malId: 1)));
      final cover = tester.getRect(find.byType(CoverImage));
      final foot = tester.getRect(find.byType(CardFoot));
      expect(foot.top, cover.bottom);
      expect(foot.height, Tokens.cardFootHeight);
      expect(
        find.descendant(
          of: find.byType(CoverWell),
          matching: find.byType(CardFoot),
        ),
        findsOneWidget,
      );
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
          row(
            malId: 1,
            name: "Frieren: Beyond Journey's End, a very long name indeed",
          ),
        ),
      );
      expect(tester.getSize(find.byType(LibraryGridCard)).height, short);
    });

    testWidgets('on a mixed tab the footer shows the mark and the count', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1), showStatus: true));
      expect(
        tester.widget<StatusMark>(find.byType(StatusMark)).status,
        EntryStatus.watching,
      );
      expect(find.text('4 / 12'), findsOneWidget);
    });

    testWidgets('on another tab the footer is the lamp and the count', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1)));
      expect(find.byType(StatusLamp), findsOneWidget);
      expect(find.byType(StatusMark), findsNothing);
      expect(find.text('4 / 12'), findsOneWidget);
    });

    testWidgets('a franchise counts its seasons', (tester) async {
      await pumpCard(
        tester,
        card(row(malId: 1, seasonsDone: 1, seasonsTotal: 2)),
      );
      expect(find.text('1 / 2 seasons'), findsOneWidget);
      expect(find.text('4 / 12'), findsNothing);
    });

    testWidgets('a finished single title is the green check', (tester) async {
      await pumpCard(
        tester,
        card(row(malId: 1, status: 'completed', watched: 12), showStatus: true),
      );
      final icon = tester.widget<AppIcon>(
        find.descendant(
          of: find.byType(StatusMark),
          matching: find.byType(AppIcon),
        ),
      );
      expect(icon.color, Tokens.ink);
    });

    testWidgets('a franchise with a season left is not green', (tester) async {
      await pumpCard(
        tester,
        card(
          row(malId: 1, status: 'completed', seasonsDone: 1, seasonsTotal: 2),
          showStatus: true,
        ),
      );
      final icon = tester.widget<AppIcon>(
        find.descendant(
          of: find.byType(StatusMark),
          matching: find.byType(AppIcon),
        ),
      );
      expect(icon.color, Tokens.inkMuted);
    });

    testWidgets('hover lights the well, lifts the card and adds the word', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1)));
      final rest = tester.getTopLeft(find.byType(CoverWell));
      expect(find.text('Watching'), findsNothing);
      await hover(tester);
      expect(tester.widget<CoverWell>(find.byType(CoverWell)).lit, isTrue);
      expect(
        tester.getTopLeft(find.byType(CoverWell)),
        rest - const Offset(0, Tokens.cardLift),
      );
      expect(find.text('Watching'), findsOneWidget);
    });

    testWidgets('under reduced motion hover lights without the lift', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1)), still: true);
      final rest = tester.getTopLeft(find.byType(CoverWell));
      await hover(tester);
      expect(tester.widget<CoverWell>(find.byType(CoverWell)).lit, isTrue);
      expect(tester.getTopLeft(find.byType(CoverWell)), rest);
    });

    testWidgets('loading details: skeletons, no tag, the footer stays real', (
      tester,
    ) async {
      await pumpCard(
        tester,
        card(row(name: '', malId: 1, hasDetails: false, episodes: null)),
      );
      expect(find.byType(KeyCaps), findsNothing);
      expect(find.byType(MalScoreLine), findsNothing);
      expect(find.byType(Skeleton), findsWidgets);
      final semantics = tester.ensureSemantics();
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('Loading details')), findsOneWidget);
      semantics.dispose();
      expect(find.text('4 / ?'), findsOneWidget);
    });

    testWidgets('loading takes the same height as a loaded card', (
      tester,
    ) async {
      await pumpCard(tester, card(row(malId: 1)));
      final loaded = tester.getSize(find.byType(LibraryGridCard)).height;
      await pumpCard(tester, card(row(name: '', malId: 1, hasDetails: false)));
      expect(tester.getSize(find.byType(LibraryGridCard)).height, loaded);
    });

    testWidgets('not linked: the saved name, "Not linked", no tag or score', (
      tester,
    ) async {
      await pumpCard(tester, card(row(name: 'Saved name')));
      expect(find.text('Saved name'), findsOneWidget);
      expect(find.text('Not linked'), findsOneWidget);
      expect(find.byType(KeyCaps), findsNothing);
      expect(find.byType(MalScoreLine), findsNothing);
      expect(find.text('4 / 12'), findsOneWidget);
    });

    Future<void> rest(WidgetTester tester, Widget card) async {
      await loadAppFonts();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            detailPageProvider(1, entryId: 'a').overrideWithBuild(
              (ref, notifier) => const DetailPageData(
                details: TitleDetails(
                  malId: 1,
                  name: 'Sousou no Frieren',
                  isFull: true,
                  fetchedAt: 0,
                  synopsis: 'The party goes home.',
                ),
              ),
            ),
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(800, 600)),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) =>
                        Align(alignment: Alignment.topLeft, child: card),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(CoverWell)));
      await tester.pump(Tokens.tipDelay);
      await tester.pumpAndSettle();
    }

    testWidgets('resting on a card opens its details beside it', (
      tester,
    ) async {
      await rest(tester, card(row(malId: 1)));
      expect(find.byType(CardDetails), findsOneWidget);
      expect(find.text('The party goes home.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(CardDetails)).dx,
        greaterThan(tester.getTopRight(find.byType(LibraryGridCard)).dx),
      );
    });

    testWidgets('a card with no MAL page has no details popover', (
      tester,
    ) async {
      await rest(tester, card(row(name: 'Saved name')));
      expect(find.byType(CardDetails), findsNothing);
    });

    testWidgets('on a touch screen there is no details popover', (
      tester,
    ) async {
      TouchTarget.debugForce = true;
      addTearDown(() => TouchTarget.debugForce = null);
      await rest(tester, card(row(malId: 1)));
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
