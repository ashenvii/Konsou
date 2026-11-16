import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/detail/watch_order.dart';
import 'package:konsou/gallery/detail_section.dart';

import 'package:konsou/shell/window_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/detail_app.dart';
import 'support/render_png.dart';

/// Renders the Detail page's parts to a PNG for looking at. Does nothing in
/// `check`. Set KONSOU_SHOTS to an output folder and run this file.
void main() {
  final folder = Platform.environment['KONSOU_SHOTS'];

  testWidgets('render the detail widgets', (tester) async {
    await loadAppFonts();
    await renderPng(
      tester,
      size: const Size(1000, 2050),
      path: '$folder/detail_widgets.png',
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: Tokens.sans),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => const ColoredBox(
                  color: Tokens.ground,
                  child: Padding(
                    padding: EdgeInsets.all(Tokens.space5),
                    child: DetailSection(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }, skip: folder == null);

  testWidgets('render the detail page', (tester) async {
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
              'width': 1280.0,
              'height': 800.0,
            },
            _ => null,
          },
        );
    const size = Size(1280, 800);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> shot(
      String name,
      String path, {
      DetailPageData? page,
      WatchOrder order = const WatchOrder([]),
      String? tab,
    }) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: detailApp(router, page: page, order: order),
        ),
      );
      await tester.pump(WindowConfig.restoreSettle);
      router.push(path);
      await tester.pumpAndSettle();
      if (tab != null) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
      }
      await capturePng(tester, key, '$folder/detail_$name.png');
      await tester.pumpWidget(const SizedBox.shrink());
    }

    final onList = DetailPageData(
      details: frierenDetails(),
      entry: frierenEntry,
    );
    final title = titlePath(frierenId);
    await shot('overview', title, page: onList, order: sampleWatchOrder);
    await shot(
      'watch_order',
      title,
      page: onList,
      order: sampleWatchOrder,
      tab: 'Watch order',
    );
    await shot(
      'my_entry',
      title,
      page: onList,
      order: sampleWatchOrder,
      tab: 'My entry',
    );
    await shot('not_on_list', title);
    await shot(
      'offline_nothing',
      title,
      page: const DetailPageData(fetch: DetailFetch.offline),
    );
    await shot('not_linked', entryPath('n'));
  }, skip: folder == null);
}
