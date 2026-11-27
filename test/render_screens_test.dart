import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/gallery/gallery_screen.dart';
import 'package:konsou/screens/library/library_grid_card.dart';
import 'package:konsou/screens/library/library_list_row.dart';
import 'package:konsou/gallery/card_pieces_section.dart';
import 'package:konsou/gallery/library_rows_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/main.dart';
import 'package:konsou/shell/app_rail.dart';
import 'package:konsou/shell/window_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/render_png.dart';

/// Renders each screen to a PNG for looking at on a phone. Does nothing in
/// `check`. To run it, set the KONSOU_SHOTS environment variable to an output
/// folder and run this file with flutter test.
/// What the pages need that the real app gets from its services: sample rows
/// and no cover files, so the covers are the blank squares.
final _pageOverrides = [
  libraryRowsProvider.overrideWith((ref) async => sampleRows),
  coverStoreProvider.overrideWithValue(null),
  coverSavedProvider.overrideWith((ref) => const Stream.empty()),
];

void main() {
  final folder = Platform.environment['KONSOU_SHOTS'];

  testWidgets('render the rail on each page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await loadAppFonts();
    // the shell saves the window size on first run; there is no window here
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          (call) async => switch (call.method) {
            'getBounds' => {
              'x': 0.0,
              'y': 0.0,
              'width': 1100.0,
              'height': 700.0,
            },
            _ => null,
          },
        );
    for (final destination in [...railDestinations, settingsDestination]) {
      final router = buildRouter();
      addTearDown(router.dispose);
      router.go(destination.path);
      await renderPng(
        tester,
        child: ProviderScope(
          overrides: _pageOverrides,
          child: KonsouApp(router: router),
        ),
        size: const Size(1100, 700),
        path: '$folder/${destination.label.toLowerCase()}.png',
      );
      await tester.pump(WindowConfig.restoreSettle);
    }
  }, skip: folder == null);

  testWidgets('render the gallery', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await loadAppFonts();
    await renderPng(
      tester,
      child: const MediaQuery(
        data: MediaQueryData(size: Size(1100, 1900)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: TextStyle(fontFamily: Tokens.sans, color: Tokens.ink),
            child: ColoredBox(color: Tokens.ground, child: GalleryScreen()),
          ),
        ),
      ),
      size: const Size(1100, 1900),
      path: '$folder/gallery.png',
    );
  }, skip: folder == null);

  testWidgets('render the library rows and cards', (tester) async {
    await loadAppFonts();
    await renderPng(
      tester,
      child: const MediaQuery(
        data: MediaQueryData(size: Size(1100, 1500)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: TextStyle(fontFamily: Tokens.sans, color: Tokens.ink),
            child: ColoredBox(
              color: Tokens.ground,
              child: Padding(
                padding: EdgeInsets.all(Tokens.space5),
                child: LibraryRowsSection(),
              ),
            ),
          ),
        ),
      ),
      size: const Size(1100, 1500),
      path: '$folder/library_rows.png',
    );
  }, skip: folder == null);

  testWidgets('render the card pieces', (tester) async {
    await loadAppFonts();
    await renderPng(
      tester,
      child: const MediaQuery(
        data: MediaQueryData(size: Size(1600, 1100)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: TextStyle(fontFamily: Tokens.sans, color: Tokens.ink),
            child: ColoredBox(
              color: Tokens.ground,
              child: Padding(
                padding: EdgeInsets.all(Tokens.space5),
                child: CardPiecesSection(),
              ),
            ),
          ),
        ),
      ),
      size: const Size(1600, 1100),
      path: '$folder/card_pieces.png',
    );
  }, skip: folder == null);

  for (final layout in ['grid', 'list']) {
    testWidgets('render the library in $layout, then scrolled', (tester) async {
      SharedPreferences.setMockInitialValues({'library.layout': layout});
      await loadAppFonts();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('window_manager'),
            (call) async => switch (call.method) {
              'getBounds' => {
                'x': 0.0,
                'y': 0.0,
                'width': 1100.0,
                'height': 700.0,
              },
              _ => null,
            },
          );
      final router = buildRouter();
      addTearDown(router.dispose);
      final key = await renderPng(
        tester,
        child: ProviderScope(
          overrides: _pageOverrides,
          child: KonsouApp(router: router),
        ),
        size: const Size(1100, 700),
        path: '$folder/library_$layout.png',
      );
      // the quick panel on the second title, the page dimmed under it
      await tester.tap(
        find.byType(layout == 'grid' ? LibraryGridCard : LibraryListRow).at(1),
        buttons: kSecondaryButton,
      );
      // the portal shows a frame later, then fades in
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await capturePng(tester, key, '$folder/library_${layout}_panel.png');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      // a short window, so the sample rows scroll and the top folds
      tester.view.physicalSize = const Size(1100, 420);
      await tester.pump();
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -160));
      await tester.pump(const Duration(milliseconds: 500));
      await capturePng(tester, key, '$folder/library_${layout}_scrolled.png');
      await tester.pump(WindowConfig.restoreSettle);
    }, skip: folder == null);
  }
}
