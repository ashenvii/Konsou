import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/main.dart';
import 'package:konsou/shell/app_rail.dart';
import 'package:konsou/shell/window_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/render_png.dart' show loadAppFonts;

void main() {
  // Every route has a barrier under its page. A click the page does not take
  // lands on it, and Flutter answers with the system alert sound: on Windows
  // the error ding, on any click on a bare part of the app.
  testWidgets('a click on a bare part of the app plays no sound', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await loadAppFonts();
    final sounds = <Object?>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemSound.play') sounds.add(call.arguments);
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      (call) async => call.method == 'getBounds'
          ? {'x': 0.0, 'y': 0.0, 'width': 1100.0, 'height': 700.0}
          : null,
    );
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    for (final path in [watchingPath, discoverPath, schedulePath]) {
      final router = buildRouter();
      addTearDown(router.dispose);
      router.go(path);
      await tester.pumpWidget(ProviderScope(child: KonsouApp(router: router)));
      await tester.pump(WindowConfig.restoreSettle);
      for (final spot in const [
        Offset(600, 400),
        Offset(1000, 650),
        Offset(200, 600),
        // the rail between its icons, and the bar beside the wordmark
        Offset(24, 400),
        Offset(250, 18),
      ]) {
        await tester.tapAt(spot);
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(sounds, isEmpty, reason: 'on $path');
    }
  });
}
