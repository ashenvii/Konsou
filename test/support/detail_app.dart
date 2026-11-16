import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konsou/app/detail_providers.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/detail/title_details.dart';
import 'package:konsou/detail/title_entry.dart';
import 'package:konsou/detail/watch_order.dart';
import 'package:konsou/gallery/detail_section.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/main.dart';

const frierenId = 52991;

const sampleSynopsis =
    'During their decade-long quest to defeat the Demon King, the members of '
    'the hero\'s party forge bonds through adventures and battles, creating '
    'unforgettable precious memories for most of them.\n\n'
    'However, the time that Frieren spends with her comrades is equivalent to '
    'merely a fraction of her life, which has lasted over a thousand years.';

/// The gallery's sample title with the prose the Overview tab shows.
TitleDetails frierenDetails({String? nsfw}) => TitleDetails(
  malId: frierenId,
  name: sampleDetails.name,
  otherName: sampleDetails.otherName,
  otherNames: sampleDetails.otherNames,
  isFull: true,
  fetchedAt: 0,
  mediaType: sampleDetails.mediaType,
  airingStatus: sampleDetails.airingStatus,
  episodes: sampleDetails.episodes,
  startDate: sampleDetails.startDate,
  endDate: sampleDetails.endDate,
  season: sampleDetails.season,
  seasonYear: sampleDetails.seasonYear,
  broadcastDay: sampleDetails.broadcastDay,
  broadcastTime: sampleDetails.broadcastTime,
  secondsPerEpisode: sampleDetails.secondsPerEpisode,
  source: sampleDetails.source,
  rating: sampleDetails.rating,
  studios: sampleDetails.studios,
  genres: sampleDetails.genres,
  synopsis: sampleSynopsis,
  background:
      'Sousou no Frieren was released on Blu-ray and DVD in seven '
      'volumes from January 24, 2024, to July 17, 2024.',
  nsfw: nsfw,
  score: sampleDetails.score,
  rank: sampleDetails.rank,
  popularity: sampleDetails.popularity,
  listUsers: sampleDetails.listUsers,
  listCounts: sampleDetails.listCounts,
);

final frierenEntry = TitleEntry(
  entryId: 'a',
  status: EntryStatus.watching,
  episodesWatched: 4,
  malId: frierenId,
  score: 8,
  notes: 'Watch with the dub next time.',
  startedAt: DateTime(2023, 10, 6).millisecondsSinceEpoch,
  finishedWatches: const [],
);

const notLinkedEntry = TitleEntry(
  entryId: 'n',
  status: EntryStatus.planned,
  episodesWatched: 0,
  finishedWatches: [],
  name: 'Scott Pilgrim Takes Off',
);

/// The app with the Detail page's providers answered from memory: the title
/// page of [frierenId] shows [page], and the entry `n` is not linked.
Widget detailApp(
  GoRouter router, {
  DetailPageData? page,
  WatchOrder order = const WatchOrder([]),
}) => ProviderScope(
  overrides: [
    libraryRowsProvider.overrideWith((ref) async => <LibraryRow>[]),
    coverStoreProvider.overrideWithValue(null),
    pageLinkingProvider.overrideWithValue(null),
    detailPageProvider(frierenId).overrideWithBuild(
      (ref, notifier) => page ?? DetailPageData(details: frierenDetails()),
    ),
    watchOrderProvider(frierenId).overrideWith((ref) async => order),
    notLinkedPageProvider('n').overrideWith(
      (ref) async =>
          const NotLinkedPage(entry: notLinkedEntry, suggestions: []),
    ),
  ],
  child: KonsouApp(router: router),
);
