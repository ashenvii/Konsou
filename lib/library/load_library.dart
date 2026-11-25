import 'package:drift/drift.dart' show QueryRow;

import '../data/databases.dart';
import '../data/record_database.dart';
import 'aired_episodes.dart';
import 'entry_status.dart';
import 'fold_franchises.dart';
import 'library_row.dart';
import 'title_language.dart';

Future<List<LibraryEntry>> loadLibraryEntries(
  Databases databases,
  TitleLanguage language,
) async {
  final rows = await databases.record.customSelect('''
    SELECT entry.entry_id, entry.name, entry.status, entry.episodes_watched,
      entry.score, entry.added_at, entry.updated_at,
      reference.provider_id AS mal_id,
      detail.provider_id IS NOT NULL AS has_details,
      detail.title, detail.title_english, detail.title_japanese,
      detail.media_type, detail.start_date, detail.episodes, detail.mal_score,
      detail.airing_status = 'not_yet_aired' AS not_aired,
      link.franchise_provider_id, link.is_extra
    FROM entry
    LEFT JOIN entry_reference reference
      ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
    LEFT JOIN details.detail detail
      ON detail.provider = 'mal' AND detail.provider_id = reference.provider_id
    LEFT JOIN details.franchise_link link
      ON link.entry_id = entry.entry_id AND link.is_placeholder = 0
    ''').get();
  return [
    for (final row in rows)
      LibraryEntry(
        entryId: row.read<String>('entry_id'),
        name: pickTitleName(row, language),
        status: EntryStatus.parse(row.read<String>('status')),
        episodesWatched: row.read<int>('episodes_watched'),
        addedAt: row.read<int>('added_at'),
        changedAt: row.read<int>('updated_at'),
        score: row.read<int?>('score'),
        malScore: row.read<double?>('mal_score'),
        malId: row.read<int?>('mal_id'),
        hasDetails: row.read<bool>('has_details'),
        episodes: row.read<int?>('episodes'),
        mediaType: row.read<String?>('media_type'),
        startDate: row.read<String?>('start_date'),
        franchiseId: row.read<int?>('franchise_provider_id'),
        isExtra: row.read<bool?>('is_extra') ?? false,
        isNotAired: row.read<bool?>('not_aired') ?? false,
      ),
  ];
}

Future<List<LibraryRow>> loadLibraryRows(
  Databases databases,
  TitleLanguage language,
) async => foldFranchises(await loadLibraryEntries(databases, language));

String pickTitleName(QueryRow row, TitleLanguage language) =>
    orderTitles(
      language,
      romaji: row.read<String?>('title'),
      english: row.read<String?>('title_english'),
      japanese: row.read<String?>('title_japanese'),
    ).firstOrNull ??
    row.read<String?>('name') ??
    '';

Future<TitleLanguage> readTitleLanguage(RecordDatabase record) async =>
    TitleLanguage.parse(await record.readSetting('title_language'));

/// What a card shows of a saved title: its shown name, type, start date,
/// episode count, MAL score, airing status, and the episodes out so far of a
/// series on the air.
typedef TitleFacts = ({
  String name,
  String? mediaType,
  String? startDate,
  int? episodes,
  double? malScore,
  String? airingStatus,
  int? airedEpisodes,
});

/// The facts of the saved titles among [malIds], the aired count as of [now].
Future<Map<int, TitleFacts>> readTitleFacts(
  RecordDatabase record,
  Iterable<int> malIds,
  TitleLanguage language, {
  required DateTime now,
}) async => {
  for (final row in await record.customSelect('''
    SELECT provider_id, title, title_english, title_japanese, media_type,
      start_date, episodes, mal_score, airing_status,
      json_extract(json, '\$.broadcast.start_time') AS broadcast_time,
      NULL AS name
    FROM details.detail
    WHERE provider = 'mal' AND provider_id IN (${malIds.join(', ')})
    ''').get())
    row.read<int>('provider_id'): (
      name: pickTitleName(row, language),
      mediaType: row.read<String?>('media_type'),
      startDate: row.read<String?>('start_date'),
      episodes: row.read<int?>('episodes'),
      malScore: row.read<double?>('mal_score'),
      airingStatus: row.read<String?>('airing_status'),
      airedEpisodes: countAiredEpisodes(
        airingStatus: row.read<String?>('airing_status'),
        mediaType: row.read<String?>('media_type'),
        startDate: row.read<String?>('start_date'),
        broadcastTime: row.read<String?>('broadcast_time'),
        total: row.read<int?>('episodes'),
        now: now,
        zeroBeforeAiring: false,
      ),
    ),
};

/// The entry on each of the MAL pages among [malIds]; where two entries share
/// a page, the one changed last.
Future<Map<int, ({String entryId, EntryStatus status, int episodesWatched})>>
readEntriesOnPages(RecordDatabase record, Iterable<int> malIds) async => {
  for (final row in await record.customSelect('''
    SELECT entry.entry_id, entry.status, entry.episodes_watched,
      reference.provider_id
    FROM entry JOIN entry_reference reference
      ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
    WHERE reference.provider_id IN (${malIds.join(', ')})
    ORDER BY entry.updated_at, entry.entry_id DESC
    ''').get())
    row.read<int>('provider_id'): (
      entryId: row.read<String>('entry_id'),
      status: EntryStatus.parse(row.read<String>('status')),
      episodesWatched: row.read<int>('episodes_watched'),
    ),
};
