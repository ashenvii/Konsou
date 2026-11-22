import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/app/routes.dart';
import 'package:konsou/app/toast_host.dart';
import 'package:konsou/components/pressable.dart';
import 'package:konsou/components/toast_view.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/detail/watch_order.dart';
import 'package:konsou/gallery/detail_section.dart';
import 'package:konsou/screens/detail/jump_bar.dart';
import 'package:konsou/screens/detail/detail_frame.dart';
import 'package:konsou/screens/detail/detail_top.dart';
import 'package:konsou/screens/detail/entry_controls.dart';
import 'package:konsou/screens/detail/detail_media.dart';
import 'package:konsou/screens/detail/detail_parts.dart';
import 'package:konsou/screens/detail/page_picker.dart';
import 'package:konsou/screens/detail/detail_header.dart';
import 'package:konsou/screens/detail/detail_scores.dart';
import 'package:konsou/screens/detail/watch_order_strip.dart';
import 'package:konsou/shell/app_shell.dart';
import 'package:konsou/shell/window_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/detail_app.dart';

JumpBar bar(WidgetTester tester) =>
    tester.widget<JumpBar>(find.byType(JumpBar));

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

    expect(
      find.descendant(
        of: find.byType(DetailTop),
        matching: find.text('Sousou no Frieren'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DetailTop),
        matching: find.text('Add to list'),
      ),
      findsOneWidget,
    );
    expect(find.text('Your score'), findsNothing);
    expect(find.text('Notes'), findsNothing);
    expect(bar(tester).labels, isNot(contains('Your entry')));
    expect(find.text('Data from MyAnimeList'), findsOneWidget);
  });

  testWidgets('on the list everything is on one page, with no tabs', (
    tester,
  ) async {
    await open(tester, title, page: onList, order: sampleWatchOrder);

    expect(
      bar(tester).labels,
      containsAllInOrder(['Overview', 'Watch order', 'Your entry']),
    );
    expect(find.text(' / 28'), findsOneWidget);
    expect(find.text('Your score'), findsOneWidget);
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

    expect(find.text('Synopsis hidden in Streamer mode'), findsOneWidget);
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

  testWidgets('the jump bar sticks at the top and takes the back button', (
    tester,
  ) async {
    await open(
      tester,
      title,
      page: onList,
      order: sampleWatchOrder,
      // short, but tall enough that the bar starts on screen under the top
      size: const Size(1200, 600),
    );
    expect(bar(tester).stuck, isFalse);
    expect(find.byType(DetailBackButton), findsNWidgets(2));

    await tester.drag(find.byType(DetailTop), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(bar(tester).stuck, isTrue);
    expect(tester.getTopLeft(find.byType(JumpBar)).dy, lessThan(100));
    // the floating one is gone; only the bar's own is left
    expect(find.byType(DetailBackButton), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(JumpBar),
        matching: find.text('Watching'),
      ),
      findsOneWidget,
    );

    // the title in the bar goes back to the top
    await tester.tap(
      find.descendant(
        of: find.byType(JumpBar),
        matching: find.text('Sousou no Frieren'),
      ),
    );
    await tester.pumpAndSettle();
    expect(bar(tester).stuck, isFalse);
  });

  testWidgets('the title leads; the rest steps down and stays soft', (
    tester,
  ) async {
    await open(tester, title, page: onList, size: const Size(1800, 900));
    final top = find.byType(DetailTop);
    Text text(Finder finder) =>
        tester.widget<Text>(find.descendant(of: top, matching: finder).first);

    final name = text(find.text('Sousou no Frieren'));
    expect(name.style?.fontSize, Tokens.text5);
    expect(name.style?.color, Tokens.ink);
    // the genres are small and muted
    final genres = text(find.textContaining('Adventure'));
    expect(genres.style?.color, Tokens.inkMuted);
    // the order down the top: names, meta, scores, then the controls
    Rect at(Finder finder) =>
        tester.getRect(find.descendant(of: top, matching: finder).first);
    expect(
      at(find.byType(DetailMeta)).top,
      greaterThan(at(find.text('Sousou no Frieren')).bottom),
    );
    expect(
      at(find.byType(DetailScores)).top,
      greaterThan(at(find.byType(DetailMeta)).bottom),
    );
    expect(
      at(find.byType(EntryControls)).top,
      greaterThan(at(find.byType(DetailScores)).bottom),
    );
  });

  testWidgets('the facts are one quiet line, the episode count cyan', (
    tester,
  ) async {
    await open(tester, title, page: onList, size: const Size(1800, 900));
    final scores = find.byType(DetailScores);
    Rect at(String text) => tester.getRect(
      find.descendant(of: scores, matching: find.textContaining(text)).first,
    );
    expect(at('rank').top, closeTo(at('episodes').top, 1));
    final episodes = tester.widget<Text>(
      find.descendant(of: scores, matching: find.textContaining('episodes')),
    );
    final number = (episodes.textSpan! as TextSpan).children!.first as TextSpan;
    expect(number.style?.color, Tokens.pop);
    final rank = tester.widget<Text>(
      find.descendant(of: scores, matching: find.textContaining('rank')),
    );
    final rankNumber = (rank.textSpan! as TextSpan).children!.first as TextSpan;
    expect(rankNumber.style?.color, Tokens.inkSoft);
  });

  testWidgets('the cover is a poster at the left, the title beside it', (
    tester,
  ) async {
    await open(tester, title, page: onList, size: const Size(1800, 900));
    final top = tester.getRect(find.byType(DetailTop));
    final poster = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is Pressable && w.label == 'Open the cover full size',
      ),
    );
    final name = tester.getRect(
      find.descendant(
        of: find.byType(DetailTop),
        matching: find.text('Sousou no Frieren'),
      ),
    );
    expect(poster.left, lessThan(top.left + Tokens.space5));
    expect(poster.width, closeTo(Tokens.detailPosterWidth, 1));
    expect(name.left, greaterThan(poster.right));
    expect(name.top, closeTo(poster.top, Tokens.space5));
  });

  testWidgets('nothing at the top is said twice below', (tester) async {
    await open(tester, title, page: onList, order: sampleWatchOrder);
    final info = find.byType(OverviewPart);
    for (final said in ['Genres', 'Studio', 'Season', 'Type', 'Episodes']) {
      expect(
        find.descendant(of: info, matching: find.text(said)),
        findsNothing,
      );
    }
  });

  testWidgets('a name in the jump bar jumps to its part', (tester) async {
    // wide enough that every name fits in the bar, in the wider test font
    await open(
      tester,
      title,
      page: onList,
      order: sampleWatchOrder,
      size: const Size(1800, 900),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(JumpBar),
        matching: find.text('Your entry'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notes'), findsOneWidget);
    expect(bar(tester).active, bar(tester).labels.indexOf('Your entry'));
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

  testWidgets('a picture opens full size and the arrows move through them', (
    tester,
  ) async {
    await open(tester, title, page: onList);
    final first = find.byWidgetPredicate(
      (w) => w is Pressable && w.label == 'Open picture 1 full size',
    );
    await tester.scrollUntilVisible(first, 300, scrollable: page);
    await tester.ensureVisible(first);
    await tester.pumpAndSettle();
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(find.byType(PictureViewer), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Pressable && w.label == 'Earlier picture',
      ),
    );
    await tester.pump();
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PictureViewer), findsNothing);
  });

  testWidgets('songs read as a track list, each its own row', (tester) async {
    await open(tester, title, page: onList);
    expect(find.text('Openings'), findsOneWidget);
    expect(find.text('Endings'), findsOneWidget);
    expect(find.text('OP 2'), findsOneWidget);
    expect(find.text('ED 1'), findsOneWidget);
    expect(find.text('Paper Lanterns'), findsOneWidget);
    expect(find.text('3 songs'), findsOneWidget);
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
          // down to the foot, past every part
          await tester.scrollUntilVisible(
            find.text('Data from MyAnimeList'),
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
