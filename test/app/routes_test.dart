import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/detail/title_entry.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/main.dart';
import 'package:konsou/shell/app_rail.dart';
import 'package:konsou/shell/window_config.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // the rail item itself, not the page title that shares its name
  Finder railItem(String label) => find.descendant(
    of: find.byType(AppRail),
    matching: find.bySemanticsLabel(label),
  );

  LibraryRow row(String entryId, {int? malId}) => LibraryRow(
    current: LibraryEntry(
      entryId: entryId,
      name: 'Saved name',
      status: 'watching',
      episodesWatched: 0,
      addedAt: 1,
      changedAt: 1,
      malId: malId,
    ),
    entryIds: [entryId],
    addedAt: 1,
    changedAt: 1,
  );

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRowsProvider.overrideWith((ref) async => <LibraryRow>[]),
          detailPageProvider(7).overrideWithBuild(
            (ref, notifier) => const DetailPageData(
              details: TitleDetails(
                malId: 7,
                name: 'Sousou no Frieren',
                isFull: true,
                fetchedAt: 1,
              ),
            ),
          ),
          notLinkedPageProvider('a').overrideWith(
            (ref) async => const NotLinkedPage(
              entry: TitleEntry(
                entryId: 'a',
                status: EntryStatus.watching,
                episodesWatched: 0,
                finishedWatches: [],
                name: 'Scott Pilgrim Takes Off',
              ),
              suggestions: [],
            ),
          ),
        ],
        child: KonsouApp(router: router),
      ),
    );
    // the shell ignores window events for a moment after it opens
    await tester.pump(WindowConfig.restoreSettle);
    await tester.pumpAndSettle();
    return router;
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

  test('a row opens its title, or its own page while it is not linked', () {
    expect(detailPathFor(row('a', malId: 7)), '/title/7?entry=a');
    expect(detailPathFor(row('a')), '/entry/a');
    expect(titlePath(7), '/title/7');
  });

  testWidgets('a title opens on its own page, inside the shell', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.push(titlePath(7));
    await tester.pumpAndSettle();

    expect(find.text('Sousou no Frieren'), findsOneWidget);
    expect(find.byType(AppRail), findsOneWidget);
  });

  testWidgets('a not-linked entry opens on its own page', (tester) async {
    final router = await pumpApp(tester);
    router.push(entryPath('a'));
    await tester.pumpAndSettle();

    expect(find.text('Scott Pilgrim Takes Off'), findsOneWidget);
  });

  testWidgets('Alt+Left goes back, and does nothing with nowhere to go', (
    tester,
  ) async {
    Future<void> altLeft() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
    }

    final router = await pumpApp(tester);
    router.push(titlePath(7));
    await tester.pumpAndSettle();
    await altLeft();
    expect(find.text('Sousou no Frieren'), findsNothing);
    expect(find.text('Library'), findsOneWidget);

    await altLeft();
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('the mouse back button goes back', (tester) async {
    final router = await pumpApp(tester);
    router.push(titlePath(7));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kBackMouseButton,
    );
    await mouse.down(tester.getCenter(find.text('Sousou no Frieren')));
    await mouse.up();
    await tester.pumpAndSettle();

    expect(find.text('Sousou no Frieren'), findsNothing);
    expect(find.text('Library'), findsOneWidget);
  });

  test('the services provider must be overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(servicesProvider), throwsA(anything));
  });
}
