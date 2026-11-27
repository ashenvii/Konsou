import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/components/skeleton.dart';
import 'package:konsou/detail/title_details.dart';
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
    double? malScore = 9.29,
    bool scorePending = false,
    bool notLinked = false,
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
              malScore: malScore,
              scorePending: scorePending,
              notLinked: notLinked,
              progress: 'Episode 4 of 28',
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('full details: names, synopsis, MAL, Aired, Length, Genres, '
      'Progress', (tester) async {
    await pump(tester, _full, DetailFetch.idle);
    expect(find.text('Sousou no Frieren'), findsOneWidget);
    expect(find.text('Frieren: Beyond Journey\'s End'), findsOneWidget);
    expect(find.text(_full.synopsis!), findsOneWidget);
    expect(tester.widget<Text>(find.text(_full.synopsis!)).maxLines, 3);
    expect(find.text('9.29'), findsOneWidget);
    expect(find.text('Sep 2023 to Mar 2024'), findsOneWidget);
    expect(find.text('24 min per episode'), findsOneWidget);
    expect(find.text('Adventure, Drama, Fantasy'), findsOneWidget);
    expect(find.text('Episode 4 of 28'), findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
  });

  testWidgets('one height whatever it holds', (tester) async {
    final heights = <double>{};
    for (final (details, fetch, notLinked) in [
      (_full, DetailFetch.idle, false),
      (_short, DetailFetch.running, false),
      (_short, DetailFetch.offline, false),
      (null, DetailFetch.idle, true),
    ]) {
      await pump(tester, details, fetch, notLinked: notLinked);
      heights.add(tester.getSize(find.byType(CardDetails)).height);
    }
    expect(heights, hasLength(1));
  });

  testWidgets('MAL\'s score is a skeleton until it has been asked for, and '
      '"?" when MAL has none', (tester) async {
    await pump(tester, _full, DetailFetch.idle, scorePending: true);
    expect(find.text('9.29'), findsNothing);
    expect(find.byType(Skeleton), findsOneWidget);
    await pump(tester, _full, DetailFetch.idle, malScore: null);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('not linked: says so in the score and the synopsis', (
    tester,
  ) async {
    await pump(tester, null, DetailFetch.idle, notLinked: true);
    expect(find.text('Not linked'), findsOneWidget);
    expect(find.text(CardDetails.notLinkedNote), findsOneWidget);
    expect(find.byType(Skeleton), findsNothing);
  });

  testWidgets('while the full fetch runs, the short facts show and the '
      'synopsis and genres are skeletons', (tester) async {
    await pump(tester, _short, DetailFetch.running);
    expect(find.text('Sousou no Frieren'), findsOneWidget);
    expect(find.text('Sep 2023 to Mar 2024'), findsOneWidget);
    expect(find.text('24 min per episode'), findsOneWidget);
    expect(find.text('Genres'), findsOneWidget);
    expect(find.byType(Skeleton), findsNWidgets(4));
    expect(find.text(CardDetails.offlineNote), findsNothing);
  });

  testWidgets('offline with no full fetch stored: one muted line, genres '
      'left empty', (tester) async {
    await pump(tester, _short, DetailFetch.offline);
    expect(find.text(CardDetails.offlineNote), findsOneWidget);
    expect(find.text('Genres'), findsOneWidget);
    expect(find.byType(Skeleton), findsNothing);
  });

  testWidgets('with nothing saved yet the card\'s name heads it', (
    tester,
  ) async {
    await pump(tester, null, DetailFetch.running);
    expect(find.text('Card name'), findsOneWidget);
  });
}
