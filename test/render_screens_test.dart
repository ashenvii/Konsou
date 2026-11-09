import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/main.dart';
import 'package:konsou/shell/app_rail.dart';
import 'package:konsou/shell/window_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/render_png.dart';

/// Renders each screen to a PNG for looking at on a phone. Does nothing in
/// `check`. To run it, set the KONSOU_SHOTS environment variable to an output
/// folder and run this file with flutter test.
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
        child: KonsouApp(router: router),
        size: const Size(1100, 700),
        path: '$folder/${destination.label.toLowerCase()}.png',
      );
      await tester.pump(WindowConfig.restoreSettle);
    }
  }, skip: folder == null);
}
