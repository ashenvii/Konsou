import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/main.dart';
import 'package:konsou/shell/app_rail.dart';
import 'package:konsou/shell/window_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // the rail item itself, not the page title that shares its name
  Finder railItem(String label) => find.descendant(
    of: find.byType(AppRail),
    matching: find.bySemanticsLabel(label),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRowsProvider.overrideWith((ref) async => <LibraryRow>[]),
        ],
        child: KonsouApp(router: router),
      ),
    );
    // the shell ignores window events for a moment after it opens
    await tester.pump(WindowConfig.restoreSettle);
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the Library', (tester) async {
    await pumpApp(tester);
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('each rail item opens its own page', (tester) async {
    await pumpApp(tester);
    for (final destination in [...railDestinations, settingsDestination]) {
      await tester.tap(railItem(destination.label));
      await tester.pumpAndSettle();
      // the page title, not the rail's spoken label
      expect(find.text(destination.label), findsOneWidget);
    }
  });

  testWidgets('the rail stays while the page changes', (tester) async {
    await pumpApp(tester);
    await tester.tap(railItem('Discover'));
    await tester.pumpAndSettle();
    expect(find.byType(AppRail), findsOneWidget);
  });

  test('the services provider must be overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(servicesProvider), throwsA(anything));
  });
}
