import 'dart:io';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
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

/// Scrolls the Library with the wheel and records frame times, in profile
/// mode, on a copy of a real data folder. Never point it at the app's own
/// folder. Run from the repo root:
///
/// flutter drive --profile -d windows
///   --driver=test_driver/integration_test.dart
///   --target=integration_test/library_scroll_test.dart
///   --dart-define=KONSOU_PERF_DATA=(a copied folder)
///   --dart-define=KONSOU_PERF_LAYOUT=list
///   --dart-define=KONSOU_PERF_TRACE=true (optional: the first pass's timeline)
///
/// The numbers land in build/integration_response_data.json.
const _dataFolder = String.fromEnvironment('KONSOU_PERF_DATA');
const _trace = bool.fromEnvironment('KONSOU_PERF_TRACE');
const _layout = String.fromEnvironment(
  'KONSOU_PERF_LAYOUT',
  defaultValue: 'list',
);

// one wheel notch on windows, before the app's own boost
const _notch = 60.0;
const _notches = 120;
const _notchGap = Duration(milliseconds: 50);
const _settle = Duration(milliseconds: 800);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('library wheel scroll', (tester) async {
    expect(_dataFolder, isNotEmpty, reason: 'KONSOU_PERF_DATA is not set');
    // the shell and the library write here; keep the owner's file untouched
    SharedPreferences.setMockInitialValues({'flutter.library.layout': _layout});
    await windowManager.ensureInitialized();
    await windowManager.maximize();

    final folder = Directory(_dataFolder);
    final services = Services(
      databases: await openDatabases(folder),
      coversFolder: Directory('${folder.path}${Platform.pathSeparator}covers'),
      // a made-up id turns the cover store on; every request is refused
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
    expect(rows, findsWidgets);
    // the kept covers list and the first covers on screen
    await Future<void>.delayed(const Duration(seconds: 2));

    final at = tester.getCenter(rows.first);
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(at));

    Future<void> wheel(double direction) async {
      for (var i = 0; i < _notches; i++) {
        await tester.sendEventToBinding(
          mouse.scroll(Offset(0, direction * _notch)),
        );
        await Future<void>.delayed(_notchGap);
      }
      await Future<void>.delayed(_settle);
    }

    final position = Scrollable.of(tester.element(rows.first)).position;
    final report = <String, Object>{};
    Future<void> measure(String key, double direction) async {
      final timings = <FrameTiming>[];
      final steps = <double>[];
      var last = position.pixels;
      void onTimings(List<FrameTiming> batch) => timings.addAll(batch);
      void onFrame(Duration _) {
        steps.add(position.pixels - last);
        last = position.pixels;
      }

      SchedulerBinding.instance.addTimingsCallback(onTimings);
      var listening = true;
      void frameLoop(Duration stamp) {
        if (!listening) return;
        onFrame(stamp);
        SchedulerBinding.instance.scheduleFrameCallback(frameLoop);
      }

      SchedulerBinding.instance.scheduleFrameCallback(frameLoop);
      await wheel(direction);
      listening = false;
      SchedulerBinding.instance.removeTimingsCallback(onTimings);
      report[key] = _summarise(timings, steps);
    }

    if (_trace) {
      // the vm timeline of the first pass: gc and what runs between frames
      await binding.traceAction(
        () => measure('down_first', 1),
        streams: ['Dart', 'Embedder', 'GC'],
      );
    } else {
      await measure('down_first', 1);
    }
    await measure('up', -1);
    await measure('down_again', 1);
    binding.reportData = {...?binding.reportData, 'layout': _layout, ...report};
  });
}

double _ms(Duration d) => d.inMicroseconds / 1000;

double _percentile(List<double> sorted, double p) =>
    sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * p).round()];

Map<String, Object> _summarise(List<FrameTiming> timings, List<double> steps) {
  final build = [for (final t in timings) _ms(t.buildDuration)]..sort();
  final raster = [for (final t in timings) _ms(t.rasterDuration)]..sort();
  final starts = [
    for (final t in timings) t.timestampInMicroseconds(FramePhase.vsyncStart),
  ];
  final gaps = [
    for (var i = 1; i < starts.length; i++) (starts[i] - starts[i - 1]) / 1000,
  ];
  final sortedGaps = [...gaps]..sort();
  final interval = _percentile(sortedGaps, 0.5);
  // when each frame was ready for the screen: a slow raster shows here even
  // when the ui thread kept time
  final shown = [
    for (final t in timings) t.timestampInMicroseconds(FramePhase.rasterFinish),
  ];
  final shownGaps = [
    for (var i = 1; i < shown.length; i++) (shown[i] - shown[i - 1]) / 1000,
  ];
  // a moving frame that went further than twice the one before it, or stood
  // still between two that moved: the eye reads both as a hitch
  var jumps = 0;
  var stalls = 0;
  for (var i = 1; i < steps.length - 1; i++) {
    final before = steps[i - 1].abs();
    final now = steps[i].abs();
    final after = steps[i + 1].abs();
    if (before > 2 && now > 2 * before + 4) jumps++;
    if (now == 0 && before > 2 && after > 2) stalls++;
  }
  return {
    'frames': timings.length,
    'interval_ms': interval,
    'gaps_over_1_5x': gaps.where((g) => g > interval * 1.5).length,
    'worst_gap_ms': sortedGaps.isEmpty ? 0 : sortedGaps.last,
    'gap_list_over_1_5x': [
      for (final g in gaps)
        if (g > interval * 1.5) g.round(),
    ],
    'late_to_screen': shownGaps.where((g) => g > interval * 1.5).length,
    'worst_screen_gap_ms': shownGaps.isEmpty
        ? 0
        : shownGaps.reduce((a, b) => a > b ? a : b),
    'build_p50': _percentile(build, 0.5),
    'build_p99': _percentile(build, 0.99),
    'build_max': build.isEmpty ? 0 : build.last,
    'raster_p50': _percentile(raster, 0.5),
    'raster_p99': _percentile(raster, 0.99),
    'raster_max': raster.isEmpty ? 0 : raster.last,
    'scroll_frames': steps.length,
    'step_jumps': jumps,
    'step_stalls': stalls,
    'max_step_px': steps.isEmpty
        ? 0
        : steps.map((s) => s.abs()).reduce((a, b) => a > b ? a : b),
  };
}
