import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/components/cover_image.dart';
import 'package:konsou/components/status_mark.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/icons/app_icons.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/screens/library/library_grid_card.dart';
import 'package:konsou/screens/library/library_list_row.dart';

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
}) {
  return LibraryRow(
    current: LibraryEntry(
      entryId: 'a',
      name: name,
      status: status,
      episodesWatched: watched,
      addedAt: 0,
      changedAt: 0,
      score: score,
      malId: malId,
      hasDetails: hasDetails,
      episodes: episodes,
      mediaType: 'tv',
      startDate: '2023-09-29',
    ),
    entryIds: const ['a'],
    addedAt: 0,
    changedAt: 0,
    seasonsDone: seasonsDone,
    seasonsTotal: seasonsTotal,
  );
}

Future<void> pump(WidgetTester tester, Widget child, {double width = 800}) {
  if (child is LibraryListRow) child = SizedBox(width: width, child: child);
  return tester.pumpWidget(
    ProviderScope(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: Size(width, 600)),
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

    testWidgets('shows the title, the type and year, progress and score', (
      tester,
    ) async {
      await pump(tester, listRow(row()));
      expect(find.text('Frieren'), findsOneWidget);
      expect(find.text('TV · 2023'), findsOneWidget);
      expect(find.text('4 / 12'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(
        tester
            .widgetList<AppIcon>(find.byType(AppIcon))
            .any((icon) => icon.def == AppIcons.star),
        isTrue,
      );
      expect(find.byKey(const Key('menu')), findsOneWidget);
    });

    testWidgets('the status word shows only when asked to', (tester) async {
      await pump(tester, listRow(row(), showStatus: true));
      expect(find.text('Watching'), findsOneWidget);
      await pump(tester, listRow(row()));
      expect(find.text('Watching'), findsNothing);
    });

    testWidgets('in a narrow row the status word joins the small line', (
      tester,
    ) async {
      await pump(tester, listRow(row(), showStatus: true), width: 360);
      expect(find.text('TV · 2023 · Watching'), findsOneWidget);
      expect(find.text('Watching'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no score leaves no star', (tester) async {
      await pump(tester, listRow(row(score: null)));
      expect(
        tester
            .widgetList<AppIcon>(find.byType(AppIcon))
            .any((icon) => icon.def == AppIcons.star),
        isFalse,
      );
    });

    testWidgets('a franchise shows its season count under the title', (
      tester,
    ) async {
      await pump(tester, listRow(row(seasonsDone: 1, seasonsTotal: 2)));
      expect(find.text('TV · 2023 · 1/2 seasons'), findsOneWidget);
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

    testWidgets('an entry with no details says so', (tester) async {
      await pump(tester, listRow(row(name: '', malId: 1, hasDetails: false)));
      expect(find.text('Loading details'), findsOneWidget);
    });

    testWidgets('a not-linked entry has a small mark', (tester) async {
      await pump(tester, listRow(row()));
      expect(find.text('Not linked'), findsOneWidget);
      await pump(tester, listRow(row(malId: 7)));
      expect(find.text('Not linked'), findsNothing);
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
    }) => LibraryGridCard(
      row: row,
      showStatus: showStatus,
      onOpen: onOpen ?? () {},
      onContextMenu: onContextMenu ?? (_) {},
    );

    testWidgets('a cover, a bold title and the type and year line', (
      tester,
    ) async {
      await pump(tester, SizedBox(width: 168, child: card(row())));
      expect(find.byType(CoverImage), findsOneWidget);
      expect(find.text('Frieren'), findsOneWidget);
      expect(find.text('TV · 2023'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Frieren')).style!.fontWeight,
        FontWeight.w700,
      );
    });

    testWidgets('the cover fills the card width', (tester) async {
      await pump(tester, SizedBox(width: 168, child: card(row())));
      expect(tester.getSize(find.byType(CoverImage)).width, 168);
    });

    testWidgets('on All the chip shows the status mark and the count', (
      tester,
    ) async {
      await pump(
        tester,
        SizedBox(width: 168, child: card(row(), showStatus: true)),
      );
      expect(find.byType(StatusMark), findsOneWidget);
      expect(
        tester.widget<StatusMark>(find.byType(StatusMark)).status,
        EntryStatus.watching,
      );
      expect(find.text('4/12'), findsOneWidget);
    });

    testWidgets('on another tab the chip is only the count', (tester) async {
      await pump(tester, SizedBox(width: 168, child: card(row())));
      expect(find.byType(StatusMark), findsNothing);
      expect(find.text('4/12'), findsOneWidget);
    });

    testWidgets('a franchise shows its season progress in the chip', (
      tester,
    ) async {
      await pump(
        tester,
        SizedBox(width: 168, child: card(row(seasonsDone: 1, seasonsTotal: 2))),
      );
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('4/12'), findsNothing);
    });

    testWidgets('a finished single title is the green check', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 168,
          child: card(row(status: 'completed', watched: 12), showStatus: true),
        ),
      );
      final icon = tester.widget<AppIcon>(
        find.descendant(
          of: find.byType(StatusMark),
          matching: find.byType(AppIcon),
        ),
      );
      expect(icon.color, Tokens.mint);
    });

    testWidgets('a franchise with a season left is not green', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 168,
          child: card(
            row(status: 'completed', seasonsDone: 1, seasonsTotal: 2),
            showStatus: true,
          ),
        ),
      );
      final icon = tester.widget<AppIcon>(
        find.descendant(
          of: find.byType(StatusMark),
          matching: find.byType(AppIcon),
        ),
      );
      expect(icon.color, Tokens.ink);
    });

    testWidgets('nothing to count leaves no chip text', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 168,
          child: card(row(watched: 0, episodes: null), showStatus: false),
        ),
      );
      expect(find.byKey(const Key('card-chip')), findsNothing);
    });

    testWidgets('a tap opens and a right click asks for the menu', (
      tester,
    ) async {
      var opened = 0;
      final asked = <Offset>[];
      await pump(
        tester,
        SizedBox(
          width: 168,
          child: card(row(), onOpen: () => opened++, onContextMenu: asked.add),
        ),
      );
      await tester.tap(find.text('Frieren'));
      expect(opened, 1);
      await tester.tap(find.text('Frieren'), buttons: kSecondaryButton);
      expect(asked, hasLength(1));
    });
  });
}
