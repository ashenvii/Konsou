import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/components/skeleton.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/screens/library/card_details.dart';

const _short = TitleDetails(
  malId: 1,
  name: 'Sousou no Frieren',
  otherNames: ['Frieren: Beyond Journey\'s End', '葬送のフリーレン'],
  isFull: false,
  fetchedAt: 0,
  airingStatus: 'finished_airing',
  episodes: 28,
  startDate: '2023-09-29',
  endDate: '2024-03-22',
  secondsPerEpisode: 1440,
);

const _full = TitleDetails(
  malId: 1,
  name: 'Sousou no Frieren',
  otherNames: ['Frieren: Beyond Journey\'s End'],
  isFull: true,
  fetchedAt: 0,
  airingStatus: 'finished_airing',
  episodes: 28,
  startDate: '2023-09-29',
  endDate: '2024-03-22',
  secondsPerEpisode: 1440,
  synopsis: 'The demon king is gone and the party goes home.',
  genres: ['Adventure', 'Drama', 'Fantasy'],
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    TitleDetails? details,
    DetailFetch fetch, {
    ValueChanged<Offset>? onStatusMenu,
  }) => tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 312,
            child: CardDetails(
              name: 'Card name',
              details: details,
              fetch: fetch,
              status: EntryStatus.watching,
              onStatusMenu: onStatusMenu ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('full details: names, synopsis, Aired, Length, Genres, the key', (
    tester,
  ) async {
    await pump(tester, _full, DetailFetch.idle);
    expect(find.text('Sousou no Frieren'), findsOneWidget);
    expect(find.text('Frieren: Beyond Journey\'s End'), findsOneWidget);
    expect(find.text(_full.synopsis!), findsOneWidget);
    expect(tester.widget<Text>(find.text(_full.synopsis!)).maxLines, 3);
    expect(find.text('Aired'), findsOneWidget);
    expect(find.text('29 Sep 2023 to 22 Mar 2024'), findsOneWidget);
    expect(find.text('Length'), findsOneWidget);
    expect(find.text('24 min per episode'), findsOneWidget);
    expect(find.text('Adventure, Drama, Fantasy'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Watching'), findsOneWidget);
    expect(tester.widget<AppButton>(find.byType(AppButton)).opensMenu, isTrue);
  });

  testWidgets('no scores, progress, type or episodes', (tester) async {
    await pump(tester, _full, DetailFetch.idle);
    expect(find.textContaining('★'), findsNothing);
    expect(find.text('28'), findsNothing);
    expect(find.text('TV'), findsNothing);
  });

  testWidgets('while the full fetch runs, the short facts show and the '
      'synopsis and genres are skeletons', (tester) async {
    await pump(tester, _short, DetailFetch.running);
    expect(find.text('Sousou no Frieren'), findsOneWidget);
    expect(find.text('29 Sep 2023 to 22 Mar 2024'), findsOneWidget);
    expect(find.text('24 min per episode'), findsOneWidget);
    expect(find.text('Genres'), findsOneWidget);
    expect(find.byType(Skeleton), findsNWidgets(4));
    expect(find.text(CardDetails.offlineNote), findsNothing);
  });

  testWidgets('offline with no full fetch stored: one muted line, no genres', (
    tester,
  ) async {
    await pump(tester, _short, DetailFetch.offline);
    expect(find.text(CardDetails.offlineNote), findsOneWidget);
    expect(find.text('Genres'), findsNothing);
    expect(find.byType(Skeleton), findsNothing);
  });

  testWidgets('with nothing saved yet the card\'s name heads it', (
    tester,
  ) async {
    await pump(tester, null, DetailFetch.running);
    expect(find.text('Card name'), findsOneWidget);
  });

  testWidgets('the status key opens the menu under itself', (tester) async {
    final asked = <Offset>[];
    await pump(tester, _full, DetailFetch.idle, onStatusMenu: asked.add);
    await tester.tap(find.byType(AppButton));
    final key = tester.getRect(find.byType(AppButton));
    expect(asked, [key.bottomLeft]);
  });
}
