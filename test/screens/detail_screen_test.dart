import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/app/toast_host.dart';
import 'package:konsou/components/peek_row.dart';
import 'package:konsou/components/pressable.dart';
import 'package:konsou/components/toast_view.dart';
import 'package:konsou/detail/watch_order.dart';
import 'package:konsou/gallery/detail_section.dart';
import 'package:konsou/screens/detail/back_bar.dart';
import 'package:konsou/screens/detail/detail_frame.dart';
import 'package:konsou/screens/detail/detail_top.dart';
import 'package:konsou/screens/detail/entry_controls.dart';
import 'package:konsou/screens/detail/next_up_row.dart';
import 'package:konsou/screens/detail/page_picker.dart';
import 'package:konsou/screens/detail/watch_order_strip.dart';
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
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    // a title the scan found but has not read shows a shimmer until it is
    // read, which never happens here; with animations off it stands still
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(detailApp(router, page: page, order: order));
    await tester.pump(WindowConfig.restoreSettle);
    router.push(path);
    await tester.pumpAndSettle();
    return router;
  }

  // the page's own scroll, not the watch order's sideways one
  final page = find
      .descendant(
        of: find.byType(DetailFrame),
        matching: find.byType(Scrollable),
      )
      .first;

  final title = titlePath(frierenId);
  final onList = DetailPageData(details: frierenDetails(), entry: frierenEntry);

  testWidgets('a title not on the list offers Add to list and no entry', (
    tester,
  ) async {
    await open(tester, title);

    expect(find.text('Sousou no Frieren'), findsOneWidget);
    expect(find.text('Add to list'), findsOneWidget);
    expect(find.text('Your score'), findsNothing);
    expect(find.text('Notes'), findsNothing);
    expect(find.text('Data from MyAnimeList'), findsOneWidget);
  });

  testWidgets('on the list everything is on one page, with no tabs', (
    tester,
  ) async {
    await open(tester, title, page: onList, order: sampleWatchOrder);

    expect(find.text('Overview'), findsNothing);
    expect(find.text(' / 28'), findsOneWidget);
    expect(find.text('Your score'), findsOneWidget);
    expect(find.byType(NextUpRow), findsOneWidget);
    expect(find.text(watchOrderSummary(sampleWatchOrder)), findsOneWidget);
    expect(find.byType(WatchOrderCard), findsWidgets);

    await tester.scrollUntilVisible(find.text('Notes'), 300, scrollable: page);
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
    expect(find.byType(EntryControls), findsNothing);
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

  testWidgets('a not-linked entry shows the page picker and its controls', (
    tester,
  ) async {
    await open(tester, entryPath('n'));

    expect(find.text('Scott Pilgrim Takes Off'), findsOneWidget);
    expect(find.byType(PagePicker), findsOneWidget);
    expect(find.text(' / ?'), findsOneWidget);
  });

  testWidgets('past the title the back bar names it and carries the status', (
    tester,
  ) async {
    await open(tester, title, page: onList, size: const Size(1200, 500));
    BackBar bar() => tester.widget<BackBar>(find.byType(BackBar));
    expect(bar().scrolled, isFalse);

    await tester.drag(find.byType(DetailTop), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(bar().scrolled, isTrue);
    expect(
      find.descendant(
        of: find.byType(BackBar),
        matching: find.text('Watching'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(BackBar),
        matching: find.text('Sousou no Frieren'),
      ),
    );
    await tester.pumpAndSettle();
    expect(bar().scrolled, isFalse);
  });

  testWidgets('the toast sits at the foot of the page', (tester) async {
    await open(tester, title);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );

    container.read(toastHostProvider.notifier).show(ToastMessage('Episode 5'));
    await tester.pump();

    expect(
      tester.getRect(find.byType(ToastView)).bottom,
      lessThanOrEqualTo(800),
    );
    container.read(toastHostProvider.notifier).dismiss();
    await tester.pump();
  });

  testWidgets('a click on the cover opens it full size, Escape closes it', (
    tester,
  ) async {
    await open(tester, title, page: onList);
    final opener = find.byWidgetPredicate(
      (w) => w is Pressable && w.label == 'Open the cover full size',
    );
    await tester.tap(opener);
    await tester.pumpAndSettle();
    expect(find.byType(CoverViewer), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CoverViewer), findsNothing);
  });

  group('every window size', () {
    // the smallest window Konsou allows and a 4K screen, with the text at
    // normal size and at 150%; nothing may spill over
    for (final size in [WindowConfig.minSize, const Size(3840, 2160)]) {
      for (final textScale in [1.0, 1.5]) {
        testWidgets('${size.width.round()} wide, text at $textScale', (
          tester,
        ) async {
          await open(
            tester,
            title,
            page: onList,
            order: sampleWatchOrder,
            size: size,
            textScale: textScale,
          );
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byType(PeekRow),
            300,
            scrollable: page,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
