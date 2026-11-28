import 'dart:convert';

import '../data/databases.dart';
import '../data/start_dates.dart';
import '../library/aired_episodes.dart';
import 'strip_title.dart';
import '../library/entry_status.dart';
import '../library/load_library.dart';
import '../library/title_language.dart';
import '../mal/detail_request.dart';
import '../mal/franchise_grouping.dart';
import '../mal/franchise_members.dart';

/// One title in a watch order, story or extra.
class WatchOrderRow extends StripTitle {
  const WatchOrderRow({
    required super.malId,
    required super.name,
    required this.isExtra,
    this.isOpenTitle = false,
    super.isLoadingDetails,
    super.isScorePending,
    super.isNotAired,
    super.mediaType,
    super.startDate,
    super.episodes,
    super.malScore,
    super.airedEpisodes,
    super.entryId,
    super.status,
    super.episodesWatched,
  });

  final bool isExtra;

  final bool isOpenTitle;

  // a finished or rewatched title counts in full, whatever its counter says
  int get episodesSeen {
    final seenAll =
        status == EntryStatus.completed || status == EntryStatus.rewatching;
    return seenAll ? episodes ?? episodesWatched : episodesWatched;
  }
}

/// A franchise's titles in watch order, with totals across them.
class WatchOrder {
  const WatchOrder(this.rows);

  final List<WatchOrderRow> rows;

  int get onList => rows.where((row) => row.entryId != null).length;

  int get episodesWatched => rows.fold(0, (sum, row) => sum + row.episodesSeen);

  int get episodesTotal =>
      rows.fold(0, (sum, row) => sum + (row.episodes ?? 0));
}

/// Builds the watch order of the franchise holding a title.
Future<WatchOrder> loadWatchOrder(
  Databases databases,
  int malId,
  TitleLanguage language,
) async {
  final record = databases.record;
  final franchise = await readFranchiseMembers(record, malId);
  if (franchise == null) return const WatchOrder([]);
  final FranchiseMembers(:saved, :places, :members) = franchise;
  final memberIds = [for (final title in members) title.id].join(', ');

  final now = DateTime.now();
  final gone = await readGonePages(record, now);

  // titles the members point at whose own details are not in yet: a story
  // title's sequel or prequel, and anyone's side story or summary
  final loading = <int, WatchOrderRow>{};
  for (final row in await record.customSelect('''
        SELECT detail.provider_id AS holder,
          json_extract(relation.value, '\$.relation_type') AS type,
          json_extract(relation.value, '\$.node.id') AS id,
          json_extract(relation.value, '\$.node.title') AS title,
          json_extract(relation.value, '\$.node.media_type') AS media_type,
          json_extract(relation.value, '\$.node.start_date') AS start_date,
          json_extract(relation.value, '\$.node.status') AS airing_status,
          json_extract(relation.value, '\$.node') AS node,
          NULLIF(json_extract(relation.value, '\$.node.num_episodes'), 0)
            AS episodes
        FROM details.detail, json_each(detail.json, '\$.related_anime') AS relation
        WHERE detail.provider = 'mal' AND detail.provider_id IN ($memberIds)
        ''').get()) {
    final id = row.read<int?>('id');
    final type = row.read<String?>('type');
    if (id == null || saved.containsKey(id) || gone.contains(id)) continue;
    final holderIsStory = !(places[row.read<int>('holder')]?.isExtra ?? true);
    final isStory = holderIsStory && storyRelations.contains(type);
    if (!isStory && parentRelations[type] != false) continue;
    if (loading[id]?.isExtra == false) continue;
    loading[id] = WatchOrderRow(
      malId: id,
      name: row.read<String?>('title') ?? '',
      isExtra: !isStory,
      isLoadingDetails: true,
      isNotAired: row.read<String?>('airing_status') == 'not_yet_aired',
      mediaType: row.read<String?>('media_type'),
      startDate: row.read<String?>('start_date'),
      episodes: row.read<int?>('episodes'),
      airedEpisodes: countAiredInListing(
        jsonDecode(row.read<String>('node')) as Map<String, dynamic>,
        now,
      ),
    );
  }
  if (members.length + loading.length < 2) return const WatchOrder([]);

  final memberList = [for (final title in members) title.id];
  final facts = await readTitleFacts(record, memberList, language, now: now);
  final entries = await readEntriesOnPages(record, memberList);

  final rows = {
    ...loading,
    for (final title in members)
      title.id: WatchOrderRow(
        malId: title.id,
        name: facts[title.id]?.name ?? '',
        isExtra: places[title.id]?.isExtra ?? false,
        isOpenTitle: title.id == malId,
        isNotAired: saved[title.id]?.airingStatus == 'not_yet_aired',
        mediaType: title.mediaType,
        startDate: title.startDate,
        episodes: facts[title.id]?.episodes,
        malScore: facts[title.id]?.malScore,
        isScorePending: facts[title.id]?.scorePending ?? false,
        airedEpisodes: facts[title.id]?.airedEpisodes,
        entryId: entries[title.id]?.entryId,
        status: entries[title.id]?.status,
        episodesWatched: entries[title.id]?.episodesWatched ?? 0,
      ),
  };
  final order = rows.values.toList()
    ..sort((a, b) {
      final byDate = compareStartDates(a.startDate, b.startDate);
      return byDate != 0 ? byDate : a.malId.compareTo(b.malId);
    });
  return WatchOrder(order);
}
