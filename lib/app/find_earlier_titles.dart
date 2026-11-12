import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../library/earlier_titles.dart';
import '../library/load_library.dart';
import '../library/title_language.dart';
import '../mal/franchise_grouping.dart';
import '../mal/saved_titles.dart';

const _skipped = {'completed', 'rewatching', 'not_interested'};

Future<List<EarlierTitle>> findEarlierTitles(
  Databases databases,
  String entryId,
  TitleLanguage language,
) async {
  final record = databases.record;
  final own = await record
      .customSelect(
        "SELECT provider_id FROM entry_reference WHERE entry_id = ? AND provider = 'mal'",
        variables: [Variable.withString(entryId)],
      )
      .getSingleOrNull();
  if (own == null) return [];
  final malId = own.read<int>('provider_id');

  final saved = await readSavedTitles(record);
  final places = groupFranchises(saved.values.map((title) => title.title));
  final franchise = places[malId]?.franchiseId;
  if (franchise == null) return [];

  final members = sortByStart([
    for (final title in saved.values)
      if (places[title.title.id]?.franchiseId == franchise) title.title,
  ]);
  final position = members.indexWhere((title) => title.id == malId);
  if (position <= 0) return [];

  final onList = {
    for (final row in await record.customSelect('''
      SELECT entry.entry_id, entry.status, reference.provider_id
      FROM entry JOIN entry_reference reference
        ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
    ''').get())
      row.read<int>('provider_id'): (
        entryId: row.read<String>('entry_id'),
        status: row.read<String>('status'),
      ),
  };

  final names = {
    for (final row in await record.customSelect('''
      SELECT provider_id, title, title_english, title_japanese, episodes,
        NULL AS name
      FROM details.detail WHERE provider = 'mal'
    ''').get())
      row.read<int>('provider_id'): (
        name: pickTitleName(row, language),
        episodes: row.read<int?>('episodes'),
      ),
  };

  final earlier = <EarlierTitle>[];
  for (final title in members.sublist(0, position)) {
    final entry = onList[title.id];
    if (entry != null && _skipped.contains(entry.status)) continue;
    if (saved[title.id]?.airingStatus == 'not_yet_aired') continue;
    if (saved[title.id]?.airingStatus == 'currently_airing') continue;
    earlier.add(
      EarlierTitle(
        malId: title.id,
        entryId: entry?.entryId,
        name: names[title.id]?.name ?? '',
        isExtra: places[title.id]?.isExtra ?? false,
        mediaType: title.mediaType,
        startDate: title.startDate,
        episodes: names[title.id]?.episodes,
        status: entry?.status,
      ),
    );
  }
  // stories first, each group already in release order
  return [
    ...earlier.where((title) => !title.isExtra),
    ...earlier.where((title) => title.isExtra),
  ];
}
