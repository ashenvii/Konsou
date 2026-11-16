import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/app/toast_host.dart';
import 'package:konsou/components/app_menu.dart';
import 'package:konsou/components/toast_view.dart';
import 'package:konsou/detail/watch_order.dart';
import 'package:konsou/gallery/detail_section.dart';
import 'package:konsou/screens/detail/back_bar.dart';
import 'package:konsou/screens/detail/detail_hero.dart';
import 'package:konsou/screens/detail/entry_bar.dart';
import 'package:konsou/screens/detail/page_picker.dart';
import 'package:konsou/screens/detail/watch_order_row.dart';
import 'package:konsou/shell/app_shell.dart';
import 'package:konsou/shell/window_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/detail_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<GoRouter> open(
    WidgetTester tester,
    String path, {
    DetailPageData? page,
    WatchOrder order = const WatchOrder([]),
    Size size = const Size(1200, 800),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(detailApp(router, page: page, order: order));
    await tester.pump(WindowConfig.restoreSettle);
    router.push(path);
    await tester.pumpAndSettle();
    return router;
  }

  final title = titlePath(frierenId);

  testWidgets('a title not on the list has no tabs and offers Add to list', (
    tester,
  ) async {
    await open(tester, title);

    expect(find.text('Sousou no Frieren'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    expect(find.text('My entry'), findsNothing);
    expect(find.text('Add to list'), findsOneWidget);
    expect(find.text('Data from MyAnimeList'), findsOneWidget);
  });

  testWidgets('on the list with a franchise it has all three tabs', (
    tester,
  ) async {
    await open(
      tester,
      title,
      page: DetailPageData(details: frierenDetails(), entry: frierenEntry),
      order: sampleWatchOrder,
    );

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('4 / 28'), findsOneWidget);

    await tester.tap(find.text('Watch order'));
    await tester.pumpAndSettle();
    expect(find.text(watchOrderSummary(sampleWatchOrder)), findsOneWidget);

    await tester.tap(find.text('My entry'));
    await tester.pumpAndSettle();
    expect(find.text('Watch with the dub next time.'), findsOneWidget);
    expect(find.text('6 Oct 2023'), findsOneWidget);
    // Rewatch is only for a finished title
    expect(find.text('Rewatch'), findsNothing);
    expect(find.text('Hold to remove'), findsWidgets);
  });

  testWidgets('offline with saved details says so and offers Retry', (
    tester,
  ) async {
    await open(
      tester,
      title,
      page: DetailPageData(
        details: frierenDetails(),
        fetch: DetailFetch.offline,
      ),
    );

    expect(find.text('Offline, showing saved details'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Data from MyAnimeList'), findsOneWidget);
  });

  testWidgets('offline with nothing saved cannot reach MyAnimeList', (
    tester,
  ) async {
    await open(
      tester,
      title,
      page: const DetailPageData(fetch: DetailFetch.offline),
    );

    expect(find.text("Can't reach MyAnimeList."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    // nothing to add without the title's details
    expect(find.byType(EntryBar), findsNothing);
  });

  testWidgets('an adult title in Streamer mode hides its synopsis', (
    tester,
  ) async {
    await open(
      tester,
      title,
      page: DetailPageData(
        details: frierenDetails(nsfw: 'black'),
        isHidden: true,
      ),
    );

    expect(find.text('Hidden in Streamer mode'), findsOneWidget);
    expect(find.textContaining('Demon King'), findsNothing);
  });

  testWidgets('a not-linked entry shows the page picker and its entry bar', (
    tester,
  ) async {
    await open(tester, entryPath('n'));

    expect(find.text('Scott Pilgrim Takes Off'), findsOneWidget);
    expect(find.byType(PagePicker), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    expect(find.text('0 / ?'), findsOneWidget);
  });

  testWidgets('past the title the back bar names it, and a click goes up', (
    tester,
  ) async {
    await open(tester, title, size: const Size(1200, 500));
    bool scrolled() => tester.widget<BackBar>(find.byType(BackBar)).scrolled;
    expect(scrolled(), isFalse);

    await tester.drag(find.byType(DetailHero), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(scrolled(), isTrue);

    await tester.tap(
      find.descendant(
        of: find.byType(BackBar),
        matching: find.text('Sousou no Frieren'),
      ),
    );
    await tester.pumpAndSettle();
    expect(scrolled(), isFalse);
  });

  testWidgets('the status menu opens above the entry bar', (tester) async {
    await open(
      tester,
      title,
      page: DetailPageData(details: frierenDetails(), entry: frierenEntry),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(EntryBar),
        matching: find.text('Watching'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byType(AppMenu)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(EntryBar)).top),
    );
  });

  testWidgets('a toast sits above the entry bar, not over it', (tester) async {
    await open(tester, title);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );

    container.read(toastHostProvider.notifier).show(ToastMessage('Episode 5'));
    await tester.pump();

    expect(
      tester.getRect(find.byType(ToastView)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(EntryBar)).top),
    );
    container.read(toastHostProvider.notifier).dismiss();
    await tester.pump();
  });
}
