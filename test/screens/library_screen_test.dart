import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/entry_actions.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/app/shortcuts.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/components/app_menu.dart';
import 'package:konsou/components/find_field.dart';
import 'package:konsou/components/heading_switcher.dart';
import 'package:konsou/components/pressable.dart';
import 'package:konsou/components/more_button.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/library/entry_edits.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/screens/library/library_grid_card.dart';
import 'package:konsou/screens/library/library_list_row.dart';
import 'package:konsou/screens/library/library_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

LibraryRow row(
  String id,
  String status, {
  String? name,
  int addedAt = 0,
  int? score,
  int seasons = 1,
}) => LibraryRow(
  current: LibraryEntry(
    entryId: id,
    name: name ?? 'Title $id',
    status: status,
    episodesWatched: 2,
    addedAt: addedAt,
    changedAt: addedAt,
    score: score,
    malId: 1,
    hasDetails: true,
    episodes: 12,
    mediaType: 'tv',
    startDate: '2023-01-01',
  ),
  entryIds: [for (var i = 0; i < seasons; i++) seasons == 1 ? id : '$id-$i'],
  addedAt: addedAt,
  changedAt: addedAt,
);

class FakeEdits implements EntryActions {
  final calls = <String>[];

  // the real actions reload the rows after every edit
  void Function()? reload;

  void _did(String call) {
    calls.add(call);
    reload?.call();
  }

  @override
  Future<EditResult> setStatus(String entryId, EntryStatus target) async {
    _did('status $entryId ${target.name}');
    return EditResult.done;
  }

  @override
  Future<EditResult> addEpisode(String entryId) async {
    _did('episode $entryId');
    return EditResult.done;
  }

  @override
  Future<EditResult> uncheck(String entryId) async {
    _did('uncheck $entryId');
    return EditResult.done;
  }

  @override
  Future<EditResult> rewatch(String entryId) async {
    _did('rewatch $entryId');
    return EditResult.done;
  }

  @override
  Future<void> remove(List<String> entryIds) async {
    _did('remove ${entryIds.join(',')}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeEdits edits;
  late int discovered;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    edits = FakeEdits();
    discovered = 0;
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    List<LibraryRow>? rows, {
    Size size = const Size(1100, 800),
    List<LibraryRow> Function()? live,
    bool keys = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRowsProvider.overrideWith(
            (ref) => live != null
                ? Future.value(live())
                : rows == null
                ? Completer<List<LibraryRow>>().future
                : Future.value(rows),
          ),
          // a plain contains match stands in for the typo-tolerant search
          libraryFindMatchesProvider.overrideWith((ref) async {
            final query = ref.watch(libraryFindChoiceProvider)?.trim() ?? '';
            if (query.isEmpty) return null;
            return {
              for (final row in rows ?? const <LibraryRow>[])
                if (row.name.toLowerCase().contains(query.toLowerCase()))
                  ...row.entryIds,
            };
          }),
          entryActionsProvider.overrideWith(
            (ref) => edits..reload = () => ref.invalidate(libraryRowsProvider),
          ),
          coverSavedProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: AppShortcuts(
              libraryOpen: keys,
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => LibraryScreen(
                      onDiscover: () => discovered++,
                      onOpen: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  final sample = [
    row('a', 'watching', name: 'Alpha', addedAt: 3, score: 5),
    row('b', 'plan_to_watch', name: 'Bravo', addedAt: 2, score: 9),
    row('c', 'completed', name: 'Charlie', addedAt: 1),
    row('d', 'on_hold', name: 'Delta', addedAt: 4),
    row('e', 'not_interested', name: 'Echo', addedAt: 5),
  ];

  List<String> order(WidgetTester tester) => [
    for (final card in tester.widgetList<LibraryGridCard>(
      find.byType(LibraryGridCard),
    ))
      card.row.name,
  ];

  // the status switcher is the heading's second word
  final heading = find.byType(HeadingSwitcher);
  final switcherButton = find.descendant(
    of: heading,
    matching: find.byType(Pressable),
  );
  final menu = find.byType(AppMenu);

  Future<void> choose(WidgetTester tester, String name) async {
    await tester.tap(switcherButton);
    await tester.pump();
    await tester.tap(find.descendant(of: menu, matching: find.text(name)));
    await tester.pump();
  }

  testWidgets('the heading shows the status and its count', (tester) async {
    await pumpScreen(tester, sample);
    final switcher = tester.widget<HeadingSwitcher>(heading);
    expect(switcher.current, 'All');
    // All leaves out Not interested
    expect(switcher.count, '4');
  });

  testWidgets('the menu lists every status with its count', (tester) async {
    await pumpScreen(tester, sample);
    await tester.tap(switcherButton);
    await tester.pump();
    for (final (name, count) in [
      ('All', '4'),
      ('Watching', '1'),
      ('Planned', '1'),
      ('Completed', '1'),
      ('On hold', '1'),
      ('Dropped', '0'),
      ('Not interested', '1'),
    ]) {
      expect(find.descendant(of: menu, matching: find.text(name)), findsOne);
      // the count in the column on the right (All's also shows in the heading)
      expect(
        find.descendant(of: menu, matching: find.text(count)),
        findsWidgets,
      );
    }
    expect(find.text('Alt + 1 to 7 switches without opening'), findsOneWidget);
  });

  testWidgets('resting the pointer on the heading opens the menu', (
    tester,
  ) async {
    await pumpScreen(tester, sample);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(switcherButton));
    await tester.pump(const Duration(milliseconds: 30));
    expect(menu, findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    expect(menu, findsOneWidget);
    // crossing onto the menu keeps it open
    await mouse.moveTo(tester.getCenter(menu));
    await tester.pump(const Duration(milliseconds: 500));
    expect(menu, findsOneWidget);
    // leaving both closes it after a moment
    await mouse.moveTo(const Offset(700, 500));
    await tester.pump(const Duration(milliseconds: 200));
    expect(menu, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(menu, findsNothing);
  });

  testWidgets('Find narrows the rows and the counts follow it', (tester) async {
    await pumpScreen(tester, sample);
    expect(find.byType(FindField), findsNothing);
    await tester.tap(find.bySemanticsLabel('Find'));
    await tester.pump();
    expect(find.byType(FindField), findsOneWidget);
    expect(find.text('Search your library'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'bra');
    await tester.pump();
    await tester.pump();
    expect(order(tester), ['Bravo']);
    expect(tester.widget<HeadingSwitcher>(heading).count, '1');
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pump();
    await tester.pump();
    expect(find.text('Nothing matches that.'), findsOneWidget);
    // Escape slides the field shut and the rows come back
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(Tokens.motionSlide);
    await tester.pump(Tokens.motionSlide);
    await tester.pump();
    expect(find.byType(FindField), findsNothing);
    expect(order(tester).length, 4);
  });

  testWidgets('keys 1 to 4 and + act on the row under the pointer', (
    tester,
  ) async {
    await pumpScreen(tester, sample, keys: true);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('Alpha')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pump();
    expect(edits.calls, ['status a completed']);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(edits.calls.last, 'episode a');
    // with the pointer off every row, nothing is touched
    await mouse.moveTo(const Offset(5, 5));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    expect(edits.calls.length, 2);
  });

  testWidgets('typing digits into Find does not set a status', (tester) async {
    await pumpScreen(tester, sample, keys: true);
    await tester.tap(find.bySemanticsLabel('Find'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '2');
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    expect(edits.calls, isEmpty);
  });

  testWidgets('resting the pointer on the magnifier opens Find', (
    tester,
  ) async {
    await pumpScreen(tester, sample);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.bySemanticsLabel('Find')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(FindField), findsOneWidget);
    // leaving it empty slides it shut again
    await mouse.moveTo(const Offset(5, 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byType(FindField), findsNothing);
  });

  testWidgets('a new status starts the list at the top', (tester) async {
    final many = [
      for (var i = 0; i < 60; i++) row('r$i', 'watching', name: 'Title $i'),
    ];
    await pumpScreen(tester, many);
    await tester.drag(find.byType(GridView), const Offset(0, -2000));
    await tester.pump();
    expect(find.text('Title 0'), findsNothing);
    await choose(tester, 'Watching');
    await tester.pump();
    expect(find.text('Title 0'), findsOneWidget);
  });

  testWidgets('a status keeps only its own rows', (tester) async {
    await pumpScreen(tester, sample);
    expect(find.byType(LibraryGridCard), findsNWidgets(4));
    await choose(tester, 'Planned');
    expect(find.byType(LibraryGridCard), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(tester.widget<HeadingSwitcher>(heading).current, 'Planned');
  });

  testWidgets('Not interested shows its rows when chosen', (tester) async {
    await pumpScreen(tester, sample);
    await choose(tester, 'Not interested');
    expect(find.text('Echo'), findsOneWidget);
    expect(find.byType(LibraryGridCard), findsOneWidget);
  });

  testWidgets('the status shows on the All tab only', (tester) async {
    await pumpScreen(tester, sample);
    expect(
      tester
          .widgetList<LibraryGridCard>(find.byType(LibraryGridCard))
          .every((card) => card.showStatus),
      isTrue,
    );
    await choose(tester, 'Watching');
    expect(
      tester.widget<LibraryGridCard>(find.byType(LibraryGridCard)).showStatus,
      isFalse,
    );
  });

  testWidgets('the sort offers Recent and A to Z only', (tester) async {
    // tall, so every group of the A to Z view is built
    await pumpScreen(tester, sample, size: const Size(1100, 3000));
    // Recent: the newest change first
    expect(order(tester).first, 'Delta');
    await tester.tap(find.text('Recent'));
    await tester.pump();
    expect(find.text('Score'), findsNothing);
    expect(find.text('Added'), findsNothing);
    await tester.tap(find.text('A to Z'));
    await tester.pump();
    expect(order(tester), ['Alpha', 'Bravo', 'Charlie', 'Delta']);
  });

  testWidgets('A to Z has a heading and a strip letter for each initial', (
    tester,
  ) async {
    await pumpScreen(tester, sample, size: const Size(1100, 700));
    await tester.tap(find.text('Recent'));
    await tester.pump();
    await tester.tap(find.text('A to Z'));
    await tester.pump();
    // heading and strip both carry the letter
    expect(find.text('A'), findsNWidgets(2));
    expect(find.text('Z'), findsOneWidget); // strip only: muted, no titles
    // a click on a letter in the strip scrolls its group into view
    expect(find.text('Delta'), findsNothing);
    await tester.tap(find.text('D').last);
    await tester.pump();
    await tester.pump();
    expect(find.text('Delta'), findsOneWidget);
    // so does typing the letter
    await tester.tap(find.text('A').last);
    await tester.pump();
    await tester.pump();
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('dragging along the strip scrubs, with a bubble on the letter', (
    tester,
  ) async {
    await pumpScreen(tester, sample, size: const Size(1100, 700));
    await tester.tap(find.text('Recent'));
    await tester.pump();
    await tester.tap(find.text('A to Z'));
    await tester.pump();
    final drag = await tester.startGesture(
      tester.getCenter(find.text('A').last),
    );
    await tester.pump();
    expect(find.text('Alpha'), findsOneWidget);
    await drag.moveTo(tester.getCenter(find.text('D').last));
    await tester.pump();
    await tester.pump();
    // the page followed the pointer to D
    expect(find.text('Delta'), findsOneWidget);
    // and the bubble shows the letter: the strip, the heading and the bubble
    expect(find.text('D'), findsNWidgets(3));
    await drag.up();
    await tester.pump();
    expect(find.text('D'), findsNWidgets(2));
  });

  testWidgets('the list switch shows rows and is remembered', (tester) async {
    await pumpScreen(tester, sample);
    expect(find.byType(LibraryListRow), findsNothing);
    await tester.tap(find.bySemanticsLabel('List view'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LibraryListRow), findsNWidgets(4));
    final saved = (await SharedPreferences.getInstance()).getString(
      'library.layout',
    );
    expect(saved, 'list');
  });

  testWidgets('an empty library says so and offers Discover', (tester) async {
    await pumpScreen(tester, const []);
    expect(find.text('Your library is empty.'), findsOneWidget);
    await tester.tap(find.text('Go to Discover'));
    expect(discovered, 1);
  });

  testWidgets('a tab with nothing in it says so', (tester) async {
    await pumpScreen(tester, [row('a', 'watching')]);
    await choose(tester, 'Completed');
    expect(find.text('Nothing here.'), findsOneWidget);
    expect(find.text('Your library is empty.'), findsNothing);
  });

  testWidgets('while loading it shows neither rows nor a message', (
    tester,
  ) async {
    await pumpScreen(tester, null);
    expect(find.byType(LibraryGridCard), findsNothing);
    expect(find.text('Nothing here.'), findsNothing);
    expect(find.text('Your library is empty.'), findsNothing);
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('right click opens the menu and a status is applied', (
    tester,
  ) async {
    await pumpScreen(tester, [row('a', 'watching', name: 'Alpha')]);
    await tester.tap(find.text('Alpha'), buttons: kSecondaryButton);
    await tester.pump();
    await tester.tap(find.text('On hold'));
    await tester.pump();
    expect(edits.calls, ['status a onHold']);
    // the menu closed
    expect(find.text('Open details'), findsNothing);
  });

  testWidgets('an edited row stays in its tab until the tab changes', (
    tester,
  ) async {
    var rows = [
      row('a', 'watching', name: 'Alpha'),
      row('b', 'plan_to_watch', name: 'Bravo'),
    ];
    await pumpScreen(tester, null, live: () => rows);
    await choose(tester, 'Planned');
    await tester.pump();
    expect(find.text('Bravo'), findsOneWidget);
    // the real edit would change the record; here the next read shows it
    rows = [rows.first, row('b', 'completed', name: 'Bravo')];
    await tester.tap(find.text('Bravo'), buttons: kSecondaryButton);
    await tester.pump();
    await tester.tap(find.text('Completed').last);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(edits.calls, ['status b completed']);
    expect(find.text('Bravo'), findsOneWidget);
    // leaving the tab lets it go
    await choose(tester, 'Watching');
    await choose(tester, 'Planned');
    expect(find.text('Bravo'), findsNothing);
  });

  testWidgets('the box completes, and unticking puts it back', (tester) async {
    await pumpScreen(tester, [
      row('a', 'watching', name: 'Alpha'),
      row('b', 'completed', name: 'Bravo'),
    ]);
    await tester.tap(find.bySemanticsLabel('List view'));
    await tester.pump();
    await tester.pump();
    final boxes = find.byType(AppCheckbox);
    expect(boxes, findsNWidgets(2));
    // both were changed at 0, so the order falls back to the title
    await tester.tap(boxes.at(0));
    await tester.pump();
    await tester.tap(boxes.at(1));
    await tester.pump();
    expect(edits.calls, ['status a completed', 'uncheck b']);
  });

  testWidgets('the three dots open the same menu, under the button', (
    tester,
  ) async {
    await pumpScreen(tester, [row('a', 'watching', name: 'Alpha')]);
    await tester.tap(find.bySemanticsLabel('List view'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(MoreButton));
    await tester.pump();
    expect(find.text('Open details'), findsOneWidget);
    await tester.tap(find.text('+ Episode'));
    await tester.pump();
    expect(edits.calls, ['episode a']);
  });

  testWidgets('removing asks first, then removes every season', (tester) async {
    await pumpScreen(tester, [row('a', 'watching', name: 'Alpha', seasons: 2)]);
    await tester.tap(find.text('Alpha'), buttons: kSecondaryButton);
    await tester.pump();
    final hold = await tester.startGesture(
      tester.getCenter(find.text('Hold to remove all 2').first),
    );
    await tester.pump(); // the fill starts timing on this frame
    await tester.pump(const Duration(milliseconds: 500));
    expect(edits.calls, isEmpty);
    await tester.pump(const Duration(milliseconds: 600));
    await hold.up();
    await tester.pump();
    expect(edits.calls, ['remove a-0,a-1']);
  });
}
