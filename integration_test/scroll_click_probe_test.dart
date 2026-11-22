import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:konsou/app/keys.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/app/secure_token_store.dart';
import 'package:konsou/app/services.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/main.dart';
import 'package:konsou/screens/library/library_grid_card.dart';
import 'package:konsou/screens/library/library_list_row.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Wheel-scrolls the Library in the real window, lets the glide settle, and
/// says whether the list takes clicks again. Run on a copy of a data folder:
///
/// flutter drive -d windows --driver=test_driver/integration_test.dart
///   --target=integration_test/scroll_click_probe_test.dart
///   --dart-define=KONSOU_PERF_DATA=(a copied folder)
const _dataFolder = String.fromEnvironment('KONSOU_PERF_DATA');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('clicks work after a wheel glide', (tester) async {
    expect(_dataFolder, isNotEmpty, reason: 'KONSOU_PERF_DATA is not set');
    SharedPreferences.setMockInitialValues({'flutter.library.layout': 'list'});
    await windowManager.ensureInitialized();
    final folder = Directory(_dataFolder);
    final services = Services(
      databases: await openDatabases(folder),
      coversFolder: Directory('${folder.path}${Platform.pathSeparator}covers'),
      keys: const Keys(
        malClientId: 'offline',
        googleClientId: '',
        googleClientSecret: '',
      ),
      client: MockClient((request) async => http.Response('', 503)),
      tokenStore: SecureTokenStore(),
      openBrowser: (url) async => false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [servicesProvider.overrideWithValue(services)],
        child: KonsouApp(router: buildRouter()),
      ),
    );
    final rows = find.byWidgetPredicate(
      (widget) => widget is LibraryListRow || widget is LibraryGridCard,
    );
    for (var i = 0; i < 300 && rows.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    final at = tester.getCenter(rows.first);
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(at));
    final position = Scrollable.of(tester.element(rows.first)).position;
    final report = <String, Object>{
      'ratio': tester.view.devicePixelRatio,
    };
    for (final (i, dy) in [60.0, 60.0, 120.0, -60.0, 60.0, 180.0].indexed) {
      await tester.sendEventToBinding(mouse.scroll(Offset(0, dy)));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      report['during_$i'] = '${position.activity.runtimeType}';
    }
    for (final wait in [500, 1000, 2000, 4000]) {
      await Future<void>.delayed(Duration(milliseconds: wait));
      report['after_${wait}ms'] =
          '${position.activity.runtimeType} '
          'ignores=${position.activity?.shouldIgnorePointer} '
          'pixels=${position.pixels}';
    }
    binding.reportData = report;
    // ignore: avoid_print
    print('PROBE $report');
  });
}
