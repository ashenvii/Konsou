import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/gallery/library_rows_section.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/screens/library/library_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/render_png.dart';

/// Renders the Library in the states the owner asked to see: loading, the
/// status menu, a row's menu with the hold button, and the letter strip. Does
/// nothing in `check`. Set KONSOU_SHOTS to an output folder and run this file.
void main() {
  final folder = Platform.environment['KONSOU_SHOTS'];

  Future<GlobalKey> pump(
    WidgetTester tester, {
    required List<LibraryRow>? rows,
    required String layout,
  }) async {
    SharedPreferences.setMockInitialValues({'library.layout': layout});
    await loadAppFonts();
    tester.view
      ..physicalSize = const Size(1100, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRowsProvider.overrideWith(
            (ref) => rows == null
                ? Completer<List<LibraryRow>>().future
                : Future.value(rows),
          ),
          coverStoreProvider.overrideWithValue(null),
          coverSavedProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1100, 700)),
              child: DefaultTextStyle(
                style: const TextStyle(fontFamily: Tokens.sans),
                child: ColoredBox(
                  color: Tokens.ground,
                  child: Overlay(
                    initialEntries: [
                      OverlayEntry(
                        builder: (_) =>
                            LibraryScreen(onDiscover: () {}, onOpen: (_) {}),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return key;
  }

  for (final layout in ['grid', 'list']) {
    testWidgets('render the loading $layout', (tester) async {
      final key = await pump(tester, rows: null, layout: layout);
      await tester.pump(const Duration(milliseconds: 500));
      await capturePng(tester, key, '$folder/loading_$layout.png');
    }, skip: folder == null);
  }

  testWidgets('render the status menu and a row menu', (tester) async {
    final key = await pump(tester, rows: sampleRows, layout: 'list');
    await tester.tap(find.text('Library'));
    final heading = find.text('All');
    await tester.tap(heading);
    await tester.pump();
    await capturePng(tester, key, '$folder/status_menu.png');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.tap(
      find.text('Kaguya-sama: Love Is War'),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    await capturePng(tester, key, '$folder/row_menu.png');
    final hold = await tester.startGesture(
      tester.getCenter(find.text('Hold to remove').first),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    await capturePng(tester, key, '$folder/row_menu_holding.png');
    await hold.cancel();
    await tester.pump();
  }, skip: folder == null);

  testWidgets('render the letter strip', (tester) async {
    final key = await pump(tester, rows: sampleRows, layout: 'grid');
    await tester.tap(find.text('Recent'));
    await tester.pump();
    await tester.tap(find.text('A to Z'));
    await tester.pump();
    final probe = await tester.startGesture(
      tester.getCenter(find.text('K').last),
    );
    await tester.pump();
    await tester.pump();
    await capturePng(tester, key, '$folder/letter_strip.png');
    await probe.up();
    await tester.pump();
  }, skip: folder == null);
}
