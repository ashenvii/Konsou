import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/components/card_foot.dart';
import 'package:konsou/components/cover_image.dart';
import 'package:konsou/components/cover_well.dart';
import 'package:konsou/components/key_cap.dart';
import 'package:konsou/components/mal_score_line.dart';
import 'package:konsou/components/skeleton.dart';
import 'package:konsou/components/status_lamp.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/detail/watch_order.dart';
import 'package:konsou/gallery/detail_section.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/screens/detail/recommendations_part.dart';
import 'package:konsou/screens/detail/strip_card.dart';
import 'package:konsou/screens/detail/watch_order_card.dart';

import '../../support/render_png.dart';

const _width = 168.0;

Future<void> pump(WidgetTester tester, Widget child) async {
  await loadAppFonts();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [coverStoreProvider.overrideWithValue(null)],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(1000, 900)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: _width, child: child),
          ),
        ),
      ),
    ),
  );
}

Widget card(WatchOrderRow row, {bool lit = false}) =>
    WatchOrderCard(row: row, width: _width, number: 4, lit: lit);

const _watching = WatchOrderRow(
  malId: 1,
  name: 'Mushoku Tensei II',
  isExtra: false,
  mediaType: 'tv',
  startDate: '2023-07-03',
  episodes: 13,
  malScore: 8.0,
  entryId: 'a',
  status: EntryStatus.watching,
  episodesWatched: 6,
);

void main() {
  group('watch order card', () {
    testWidgets('the number with its type and year, then the strip card', (
      tester,
    ) async {
      await pump(tester, card(_watching));
      expect(find.text('4'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
      expect(find.text('6 / 13'), findsOneWidget);
      expect(find.text('8.00'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);
      expect(find.text('Mushoku Tensei II'), findsOneWidget);
    });

    testWidgets('the footer sits in the well under the cover', (tester) async {
      await pump(tester, card(_watching));
      expect(
        find.descendant(
          of: find.byType(CoverWell),
          matching: find.byType(CardFoot),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byType(CardFoot)).top,
        tester.getRect(find.byType(CoverImage)).bottom,
      );
    });

    testWidgets('not on the list: no lamp, the total, the word', (
      tester,
    ) async {
      await pump(
        tester,
        card(
          const WatchOrderRow(
            malId: 2,
            name: 'Part 2',
            isExtra: false,
            mediaType: 'tv',
            startDate: '2024-04-08',
            episodes: 12,
          ),
        ),
      );
      expect(find.byType(StatusLamp), findsNothing);
      expect(find.text('12 ep'), findsOneWidget);
      expect(find.text('Not on your list'), findsOneWidget);
    });

    testWidgets('airing and not on the list: the episodes out so far', (
      tester,
    ) async {
      await pump(
        tester,
        card(
          const WatchOrderRow(
            malId: 2,
            name: 'Airing',
            isExtra: false,
            episodes: 12,
            airedEpisodes: 8,
          ),
        ),
      );
      expect(find.text('Ep 8 / 12'), findsOneWidget);
    });

    testWidgets('a title not aired yet gives its whole date', (tester) async {
      await pump(
        tester,
        card(
          const WatchOrderRow(
            malId: 3,
            name: 'Season 3',
            isExtra: false,
            isNotAired: true,
            mediaType: 'tv',
            startDate: '2027-01-12',
          ),
        ),
      );
      expect(find.text('12 Jan 2027'), findsOneWidget);
      expect(find.text('Not aired yet'), findsOneWidget);
    });

    testWidgets('an extra wears the Extra key cap at the cover\'s foot', (
      tester,
    ) async {
      await pump(
        tester,
        card(
          const WatchOrderRow(
            malId: 4,
            name: 'Side story',
            isExtra: true,
            mediaType: 'special',
          ),
        ),
      );
      final tag = find.widgetWithText(KeyCaps, 'Extra');
      expect(tag, findsOneWidget);
      final cover = tester.getRect(find.byType(CoverImage));
      expect(tester.getBottomRight(tag), cover.bottomRight);
    });

    testWidgets('the open title\'s state is ink, the rest muted', (
      tester,
    ) async {
      await pump(tester, card(_watching));
      expect(
        tester.widget<Text>(find.text('Watching')).style?.color,
        Tokens.inkMuted,
      );
      await pump(
        tester,
        card(
          const WatchOrderRow(
            malId: 1,
            name: 'Open',
            isExtra: false,
            isOpenTitle: true,
            entryId: 'a',
            status: EntryStatus.watching,
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Watching')).style?.color,
        Tokens.ink,
      );
    });

    testWidgets('loading details: skeleton for the score, no state word', (
      tester,
    ) async {
      await pump(tester, card(sampleWatchOrder.rows[3]));
      expect(find.byType(MalScoreLine), findsNothing);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text('Loading details'), findsNothing);
    });

    testWidgets('a long name and a short one take the same height', (
      tester,
    ) async {
      await pump(tester, card(_watching));
      final short = tester.getSize(find.byType(WatchOrderCard)).height;
      await pump(
        tester,
        card(
          const WatchOrderRow(
            malId: 1,
            name: 'Mushoku Tensei II: Isekai Ittara Honki Dasu Part 2, a long one',
            isExtra: false,
            entryId: 'a',
            status: EntryStatus.watching,
          ),
        ),
      );
      expect(tester.getSize(find.byType(WatchOrderCard)).height, short);
    });

    testWidgets('the arrows centre on the cover', (tester) async {
      await pump(tester, card(_watching));
      final cover = tester.getRect(find.byType(CoverImage));
      final context = tester.element(find.byType(WatchOrderCard));
      expect(
        watchOrderArrowTop(context, _width) + Tokens.controlHeight / 2,
        closeTo(cover.center.dy, 0.01),
      );
    });
  });

  group('recommendations', () {
    testWidgets('on the list: its state; off it: how many recommend it', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await loadAppFonts();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [coverStoreProvider.overrideWithValue(null)],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1000, 900)),
              child: RecommendationsPart(
                titles: sampleRecommended,
                onOpen: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(StripCard), findsNWidgets(3));
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('96 users'), findsOneWidget);
      expect(find.text('Ep 8 / 24'), findsOneWidget);
      expect(find.text('24 ep'), findsOneWidget);
      expect(find.text('8.36'), findsOneWidget);
    });
  });
}
