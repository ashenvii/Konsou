import '../data/databases.dart';
import '../library/entry_status.dart';
import '../library/load_library.dart';
import '../library/title_language.dart';
import '../mal/franchise_grouping.dart';
import '../mal/franchise_members.dart';

class WatchOrderRow {
  const WatchOrderRow({
    required this.malId,
    required this.name,
    required this.isExtra,
    this.isOpenTitle = false,
    this.isLoadingDetails = false,
    this.isNotAired = false,
    this.mediaType,
    this.startDate,
    this.episodes,
    this.entryId,
    this.status,
    this.episodesWatched = 0,
  });

  final int malId;
  final String name;
  final bool isExtra;

  final bool isOpenTitle;

  final bool isLoadingDetails;
  final bool isNotAired;
  final String? mediaType;
  final String? startDate;
  final int? episodes;

  final String? entryId;
  final EntryStatus? status;
  final int episodesWatched;

  // a finished or rewatched title counts in full, whatever its counter says
  int get episodesSeen {
    final seenAll =
        status == EntryStatus.completed || status == EntryStatus.rewatching;
    return seenAll ? episodes ?? episodesWatched : episodesWatched;
  }
}

class WatchOrder {
  const WatchOrder(this.rows);

  final List<WatchOrderRow> rows;

  int get onList => rows.where((row) => row.entryId != null).length;

  int get episodesWatched => rows.fold(0, (sum, row) => sum + row.episodesSeen);

  int get episodesTotal =>
      rows.fold(0, (sum, row) => sum + (row.episodes ?? 0));
}

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

  final gone = {
    for (final row
        in await record
            .customSelect(
              "SELECT provider_id FROM details.gone_page WHERE provider = 'mal'",
            )
            .get())
      row.read<int>('provider_id'),
  };

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
    );
  }
  if (members.length + loading.length < 2) return const WatchOrder([]);

  final names = {
    for (final row in await record.customSelect('''
          SELECT provider_id, title, title_english, title_japanese, episodes,
            NULL AS name
          FROM details.detail
          WHERE provider = 'mal' AND provider_id IN ($memberIds)
          ''').get())
      row.read<int>('provider_id'): (
        name: pickTitleName(row, language),
        episodes: row.read<int?>('episodes'),
      ),
  };
  // the entry changed last wins where two share a page
  final entries = {
    for (final row in await record.customSelect('''
          SELECT entry.entry_id, entry.status, entry.episodes_watched,
            reference.provider_id
          FROM entry JOIN entry_reference reference
            ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
          WHERE reference.provider_id IN ($memberIds)
          ORDER BY entry.updated_at, entry.entry_id DESC
          ''').get())
      row.read<int>('provider_id'): row,
  };

  final rows = {
    ...loading,
    for (final title in members)
      title.id: WatchOrderRow(
        malId: title.id,
        name: names[title.id]?.name ?? '',
        isExtra: places[title.id]?.isExtra ?? false,
        isOpenTitle: title.id == malId,
        isNotAired: saved[title.id]?.airingStatus == 'not_yet_aired',
        mediaType: title.mediaType,
        startDate: title.startDate,
        episodes: names[title.id]?.episodes,
        entryId: entries[title.id]?.read<String>('entry_id'),
        status: switch (entries[title.id]) {
          final entry? => EntryStatus.parse(entry.read<String>('status')),
          null => null,
        },
        episodesWatched: entries[title.id]?.read<int>('episodes_watched') ?? 0,
      ),
  };
  final order = sortByStart([
    for (final row in rows.values)
      FranchiseTitle(
        id: row.malId,
        mediaType: row.mediaType,
        startDate: row.startDate,
        relations: const [],
      ),
  ]);
  return WatchOrder([for (final title in order) rows[title.id]!]);
}
