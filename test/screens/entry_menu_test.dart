import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_menu.dart';
import 'package:konsou/components/hold_row.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/screens/library/entry_menu.dart';

LibraryRow row({String status = 'watching', int seasons = 1}) => LibraryRow(
  current: LibraryEntry(
    entryId: 'a',
    name: 'Frieren',
    status: status,
    episodesWatched: 3,
    addedAt: 0,
    changedAt: 0,
  ),
  entryIds: [for (var i = 0; i < seasons; i++) 'e$i'],
  addedAt: 0,
  changedAt: 0,
  seasonsDone: seasons > 1 ? 0 : null,
  seasonsTotal: seasons > 1 ? seasons : null,
);

void main() {
  late List<String> taken;

  Future<void> pumpMenu(WidgetTester tester, LibraryRow row) {
    taken = [];
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: EntryMenu(
            row: row,
            onStatus: (status) => taken.add('status ${status.name}'),
            onAddEpisode: () => taken.add('episode'),
            onRewatch: () => taken.add('rewatch'),
            onOpen: () => taken.add('open'),
            onRemove: () => taken.add('remove'),
            onClose: () => taken.add('close'),
          ),
        ),
      ),
    );
  }

  List<String> labels(WidgetTester tester) => [
    for (final entry in tester.widget<AppMenu>(find.byType(AppMenu)).entries)
      entry.label,
  ];

  testWidgets('four statuses with their keys, then the others', (tester) async {
    await pumpMenu(tester, row(status: 'plan_to_watch'));
    final entries = tester.widget<AppMenu>(find.byType(AppMenu)).entries;
    expect(
      [for (final e in entries.take(4)) (e.label, e.shortcut)],
      [
        ('Watching', '1'),
        ('Planned', '2'),
        ('Completed', '3'),
        ('On hold', '4'),
      ],
    );
    expect(labels(tester), containsAll(['Dropped', 'Not interested']));
    expect(labels(tester).last, 'Hold to remove');
  });

  testWidgets('the current status has the check', (tester) async {
    await pumpMenu(tester, row(status: 'on_hold'));
    final selected = tester
        .widget<AppMenu>(find.byType(AppMenu))
        .entries
        .where((e) => e.selected)
        .map((e) => e.label);
    expect(selected, ['On hold']);
    expect(find.byType(AppIcon), findsOneWidget);
  });

  testWidgets('+ Episode only while watching or rewatching', (tester) async {
    await pumpMenu(tester, row(status: 'watching'));
    expect(labels(tester), contains('+ Episode'));
    await pumpMenu(tester, row(status: 'rewatching'));
    expect(labels(tester), contains('+ Episode'));
    await pumpMenu(tester, row(status: 'completed'));
    expect(labels(tester), isNot(contains('+ Episode')));
  });

  testWidgets('Rewatch only for a completed title', (tester) async {
    await pumpMenu(tester, row(status: 'completed'));
    expect(labels(tester), contains('Rewatch'));
    await pumpMenu(tester, row(status: 'watching'));
    expect(labels(tester), isNot(contains('Rewatch')));
  });

  testWidgets('choosing a status runs it and closes the menu', (tester) async {
    await pumpMenu(tester, row());
    await tester.tap(find.text('Completed'));
    expect(taken, ['status completed', 'close']);
  });

  testWidgets('Open details, + Episode and Rewatch run and close', (
    tester,
  ) async {
    await pumpMenu(tester, row());
    await tester.tap(find.text('Open details'));
    await tester.tap(find.text('+ Episode'));
    expect(taken, ['open', 'close', 'episode', 'close']);
    await pumpMenu(tester, row(status: 'completed'));
    await tester.tap(find.text('Rewatch'));
    expect(taken, ['rewatch', 'close']);
  });

  testWidgets('Remove runs only after it is held for a second', (tester) async {
    await pumpMenu(tester, row());
    // a click does nothing
    await tester.tap(find.text('Hold to remove').first);
    await tester.pump();
    expect(taken, isEmpty);
    // let go early and nothing runs
    final early = await tester.startGesture(
      tester.getCenter(find.text('Hold to remove').first),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await early.up();
    await tester.pump(const Duration(seconds: 2));
    expect(taken, isEmpty);
    // held the whole time it removes
    final held = await tester.startGesture(
      tester.getCenter(find.text('Hold to remove').first),
    );
    await tester.pump(); // the fill starts timing on this frame
    await tester.pump(const Duration(milliseconds: 500));
    expect(taken, isEmpty);
    await tester.pump(const Duration(milliseconds: 600));
    expect(taken, ['remove', 'close']);
    await held.up();
  });

  testWidgets('Enter held on the row removes too', (tester) async {
    await pumpMenu(tester, row());
    bool onHoldRow() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<HoldRow>() !=
        null;
    // the nearest Focus above the label is the row's own
    Focus.of(tester.element(find.text('Hold to remove').first)).requestFocus();
    await tester.pump();
    expect(onHoldRow(), isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // let go before the second is up: nothing runs
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(seconds: 2));
    expect(taken, isEmpty);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(taken, ['remove', 'close']);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
  });

  testWidgets('a franchise says how many it removes', (tester) async {
    await pumpMenu(tester, row(seasons: 3));
    expect(find.text('Hold to remove all 3'), findsWidgets);
  });

  testWidgets('keys 1 to 4 set a status and close', (tester) async {
    await pumpMenu(tester, row());
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    expect(taken, ['status planned', 'close', 'status onHold', 'close']);
  });

  testWidgets('plus adds an episode while watching, and does nothing else', (
    tester,
  ) async {
    await pumpMenu(tester, row());
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    expect(taken, ['episode', 'close']);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(taken, ['episode', 'close', 'episode', 'close']);
    await pumpMenu(tester, row(status: 'completed'));
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    expect(taken, isEmpty);
  });
}
