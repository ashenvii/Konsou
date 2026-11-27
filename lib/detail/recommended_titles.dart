import '../data/databases.dart';
import '../library/load_library.dart';
import '../library/title_language.dart';
import 'strip_title.dart';
import 'title_details.dart';

/// A title MAL's users recommend: what Konsou has of it, its cover link for a
/// title with nothing saved, and how many recommend it.
class RecommendedTitle {
  const RecommendedTitle({required this.title, this.pictureUrl, this.note});

  final StripTitle title;
  final String? pictureUrl;

  /// "412 users".
  final String? note;
}

/// [titles] in MAL's order, each with its saved details and entry.
Future<List<RecommendedTitle>> loadRecommendedTitles(
  Databases databases,
  List<LinkedTitle> titles,
  TitleLanguage language, {
  required DateTime now,
}) async {
  if (titles.isEmpty) return const [];
  final ids = [for (final title in titles) title.malId];
  final facts = await readTitleFacts(databases.record, ids, language, now: now);
  final entries = await readEntriesOnPages(databases.record, ids);
  RecommendedTitle readTitle(LinkedTitle linked) {
    final saved = facts[linked.malId];
    final entry = entries[linked.malId];
    return RecommendedTitle(
      title: StripTitle(
        malId: linked.malId,
        name: switch (saved?.name) {
          final name? when name.isNotEmpty => name,
          _ => linked.name,
        },
        isLoadingDetails: saved == null,
        isNotAired: saved?.airingStatus == 'not_yet_aired',
        mediaType: saved?.mediaType,
        startDate: saved?.startDate,
        episodes: saved?.episodes,
        malScore: saved?.malScore,
        isScorePending: saved?.scorePending ?? false,
        airedEpisodes: saved?.airedEpisodes,
        entryId: entry?.entryId,
        status: entry?.status,
        episodesWatched: entry?.episodesWatched ?? 0,
      ),
      pictureUrl: linked.pictureUrl,
      note: linked.note,
    );
  }

  return [for (final linked in titles) readTitle(linked)];
}
