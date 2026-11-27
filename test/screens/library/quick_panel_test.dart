import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/components/pressable.dart';
import 'package:konsou/components/raised_key.dart';
import 'package:konsou/components/remove_key.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/screens/library/quick_panel.dart';

import '../../support/render_png.dart';

LibraryRow row({String status = 'watching', int seasons = 1}) => LibraryRow(
  current: LibraryEntry(
    entryId: 'a',
    name: 'Frieren',
    status: EntryStatus.parse(status),
    episodesWatched: 3,
    episodes: 28,
    addedAt: 0,
    changedAt: 0,
  ),
  entryIds: [for (var i = 0; i < seasons; i++) 'e$i'],
  addedAt: 0,
  changedAt: 0,
  seasonsDone: seasons > 1 ? 0 : null,
  seasonsTotal: seasons > 1 ? seasons : null,
  seasonNumber: seasons > 1 ? 1 : null,
);

void main() {
  late List<String> taken;

  Future<void> pumpPanel(WidgetTester tester, LibraryRow row) async {
    taken = [];
    await loadAppFonts();
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 900)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          // a new overlay each time, as its entries are only read once
          child: Overlay(
            key: UniqueKey(),
            initialEntries: [
              OverlayEntry(
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: QuickPanel(
                    row: row,
                    // as tall as real details, so the corner key sits inside them
                    details: const SizedBox(
                      height: 200,
                      child: Text('Details'),
                    ),
                    onStatus: (status) => taken.add('status ${status.name}'),
                    onOpen: () => taken.add('open'),
                    onRemove: () => taken.add('remove'),
                    onClose: () => taken.add('close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Finder statusKey(String label) =>
      find.byWidgetPredicate((w) => w is Pressable && w.label == label);

  bool lit(WidgetTester tester, String label) => tester
      .widget<RaisedKey>(
        find.descendant(of: statusKey(label), matching: find.byType(RaisedKey)),
      )
      .primary;

  testWidgets('the details on top, four status keys, the other two as words', (
    tester,
  ) async {
    await pumpPanel(tester, row(status: 'plan_to_watch'));
    expect(find.text('Details'), findsOneWidget);
    expect(tester.getSize(find.byType(QuickPanel)).width, Tokens.popoverWidth);
    for (final status in ['Watching', 'Planned', 'Completed', 'On hold']) {
      expect(statusKey(status), findsOneWidget);
    }
    expect(find.text('Dropped'), findsOneWidget);
    expect(find.text('Not interested'), findsOneWidget);
    expect(find.text('+1'), findsNothing);
    expect(find.text('Rewatch'), findsNothing);
  });

  testWidgets('the current status is the lit key, its word under the keys', (
    tester,
  ) async {
    await pumpPanel(tester, row(status: 'on_hold'));
    expect(lit(tester, 'On hold'), isTrue);
    expect(lit(tester, 'Watching'), isFalse);
    expect(find.text('On hold'), findsOneWidget);
  });

  testWidgets('a worded status lights no key and names itself', (tester) async {
    await pumpPanel(tester, row(status: 'dropped'));
    for (final status in ['Watching', 'Planned', 'Completed', 'On hold']) {
      expect(lit(tester, status), isFalse);
    }
    // the word under the keys and the word to pick it
    expect(find.text('Dropped'), findsNWidgets(2));
  });

  testWidgets('one height for every status', (tester) async {
    final heights = <double>{};
    for (final status in [
      'watching',
      'plan_to_watch',
      'completed',
      'on_hold',
      'dropped',
      'not_interested',
      'rewatching',
    ]) {
      await pumpPanel(tester, row(status: status));
      heights.add(tester.getSize(find.byType(QuickPanel)).height);
    }
    expect(heights, hasLength(1));
  });

  testWidgets('a status key or word sets it and the panel stays open', (
    tester,
  ) async {
    await pumpPanel(tester, row());
    await tester.tap(statusKey('Completed'));
    await tester.tap(find.text('Not interested'));
    expect(taken, ['status completed', 'status notInterested']);
  });

  testWidgets('Open details is a key, and runs and closes', (tester) async {
    await pumpPanel(tester, row());
    expect(find.widgetWithText(AppButton, 'Open details'), findsOneWidget);
    await tester.tap(find.text('Open details'));
    expect(taken, ['open', 'close']);
  });

  testWidgets('the trash key removes only after a second\'s hold', (
    tester,
  ) async {
    await pumpPanel(tester, row());
    final trash = find.byType(RemoveKey);
    final held = await tester.startGesture(tester.getCenter(trash));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(taken, isEmpty);
    await tester.pump(const Duration(milliseconds: 600));
    expect(taken, ['remove', 'close']);
    await held.up();
  });

  testWidgets('a tap on the trash key says to hold, and removes nothing', (
    tester,
  ) async {
    await pumpPanel(tester, row());
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byType(RemoveKey)));
    await tester.pump();
    await tester.tap(find.byType(RemoveKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(taken, isEmpty);
    expect(find.text(RemoveKey.tapWords), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('the trash key says what holding removes', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpPanel(tester, row());
    expect(
      find.bySemanticsLabel('Hold to remove from your list'),
      findsOneWidget,
    );
    await pumpPanel(tester, row(seasons: 3));
    expect(
      tester.widget<RemoveKey>(find.byType(RemoveKey)).words,
      'Hold to remove all 3 seasons',
    );
    semantics.dispose();
  });

  testWidgets('keys 1 to 4 set a status, the panel stays', (tester) async {
    await pumpPanel(tester, row());
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    expect(taken, ['status planned', 'status onHold']);
  });

  testWidgets('plus no longer adds an episode', (tester) async {
    await pumpPanel(tester, row());
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    expect(taken, isEmpty);
  });

  testWidgets('a right click on the trash key starts no hold', (tester) async {
    await pumpPanel(tester, row());
    final held = await tester.startGesture(
      tester.getCenter(find.byType(RemoveKey)),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    expect(taken, isEmpty);
    await held.up();
  });
}
