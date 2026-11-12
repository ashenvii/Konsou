import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/entry_actions.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/components/more_button.dart';
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

  @override
  Future<EditResult> setStatus(String entryId, EntryStatus target) async {
    calls.add('status $entryId ${target.name}');
    return EditResult.done;
  }

  @override
  Future<EditResult> addEpisode(String entryId) async {
    calls.add('episode $entryId');
    return EditResult.done;
  }

  @override
  Future<EditResult> uncheck(String entryId) async {
    calls.add('uncheck $entryId');
    return EditResult.done;
  }

  @override
  Future<EditResult> rewatch(String entryId) async {
    calls.add('rewatch $entryId');
    return EditResult.done;
  }

  @override
  Future<void> remove(List<String> entryIds) async {
    calls.add('remove ${entryIds.join(',')}');
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
          entryActionsProvider.overrideWithValue(edits),
          coverSavedProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(size: size),
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

  // the status switcher is the button that carries a count
  final switcherButton = find.byWidgetPredicate(
    (widget) => widget is AppButton && widget.count != null,
  );

  Future<void> choose(WidgetTester tester, String entry) async {
    // the heading's switcher opens the menu; entries read "Name  count"
    await tester.tap(switcherButton);
    await tester.pump();
    await tester.tap(find.text(entry));
    await tester.pump();
  }

  testWidgets('the heading shows the status and its count', (tester) async {
    await pumpScreen(tester, sample);
    final switcher = tester.widget<AppButton>(switcherButton);
    expect(switcher.label, 'All');
    // All leaves out Not interested
    expect(switcher.count, 4);
  });

  testWidgets('the menu lists every status with its count', (tester) async {
    await pumpScreen(tester, sample);
    await tester.tap(switcherButton);
    await tester.pump();
    for (final entry in [
      'All  4',
      'Watching  1',
      'Planned  1',
      'Completed  1',
      'On hold  1',
      'Dropped  0',
      'Not interested  1',
    ]) {
      expect(find.text(entry), findsOneWidget);
    }
  });

  testWidgets('a status keeps only its own rows', (tester) async {
    await pumpScreen(tester, sample);
    expect(find.byType(LibraryGridCard), findsNWidgets(4));
    await choose(tester, 'Planned  1');
    expect(find.byType(LibraryGridCard), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(tester.widget<AppButton>(switcherButton).label, 'Planned');
  });

  testWidgets('Not interested shows its rows when chosen', (tester) async {
    await pumpScreen(tester, sample);
    await choose(tester, 'Not interested  1');
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
    await choose(tester, 'Watching  1');
    expect(
      tester.widget<LibraryGridCard>(find.byType(LibraryGridCard)).showStatus,
      isFalse,
    );
  });

  testWidgets('the sort offers Recent and A to Z only', (tester) async {
    await pumpScreen(tester, sample);
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
    await choose(tester, 'Completed  0');
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
    await choose(tester, 'Planned  1');
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
    await choose(tester, 'Watching  1');
    await choose(tester, 'Planned  0');
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
    await tester.tap(find.text('Remove from list'));
    await tester.pump();
    expect(edits.calls, isEmpty);
    await tester.tap(find.text('Remove all 2?'));
    await tester.pump();
    expect(edits.calls, ['remove a-0,a-1']);
  });
}
