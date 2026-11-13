import 'package:drift/drift.dart' show QueryRow;

import '../data/databases.dart';
import '../data/record_database.dart';
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
      detail.media_type, detail.start_date, detail.episodes,
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
        status: row.read<String>('status'),
        episodesWatched: row.read<int>('episodes_watched'),
        addedAt: row.read<int>('added_at'),
        changedAt: row.read<int>('updated_at'),
        score: row.read<int?>('score'),
        malId: row.read<int?>('mal_id'),
        hasDetails: row.read<bool>('has_details'),
        episodes: row.read<int?>('episodes'),
        mediaType: row.read<String?>('media_type'),
        startDate: row.read<String?>('start_date'),
        franchiseId: row.read<int?>('franchise_provider_id'),
        isExtra: row.read<bool?>('is_extra') ?? false,
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

Future<TitleLanguage> readTitleLanguage(RecordDatabase record) async {
  final row =
      await (record.select(record.setting)
            ..where((setting) => setting.key.equals('title_language')))
          .getSingleOrNull();
  return TitleLanguage.parse(row?.value);
}
