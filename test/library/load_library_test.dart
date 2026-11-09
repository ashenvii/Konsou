import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/import/import_old_list.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/library/library_view.dart';
import 'package:konsou/library/load_library.dart';

import '../support/test_list.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_load_library');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> addEntry(
    String id,
    String status, {
    String? name,
    int? malId,
    int? franchise,
    bool extra = false,
    bool placeholder = false,
    String? json,
    int score = 0,
  }) async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: id,
            name: Value(name),
            status: status,
            score: Value(score == 0 ? null : score),
            addedAt: 1,
            progressChangedAt: 1,
          ),
        );
    if (malId != null) {
      await record
          .into(record.entryReference)
          .insert(
            EntryReferenceCompanion.insert(
              entryId: id,
              provider: 'mal',
              providerId: malId,
            ),
          );
    }
    if (json != null && malId != null) {
      final details = databases.details;
      await details
          .into(details.detail)
          .insert(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: malId,
              fetchedAt: 1,
              json: json,
            ),
          );
    }
    if (franchise != null) {
      await record.customStatement(
        'INSERT INTO details.franchise_link (entry_id, franchise_provider, '
        "franchise_provider_id, is_extra, is_placeholder) VALUES (?, 'mal', ?, ?, ?)",
        [id, franchise, extra ? 1 : 0, placeholder ? 1 : 0],
      );
    }
  }

  const season1 =
      '{"title": "Sousou no Frieren", "alternative_titles": '
      '{"en": "Frieren", "ja": "葬送のフリーレン"}, '
      '"media_type": "tv", "start_date": "2023-09-29", "num_episodes": 28}';
  const season2 =
      '{"title": "Sousou no Frieren 2nd Season", "media_type": "tv", '
      '"start_date": "2026-01-16", "num_episodes": 10}';

  test('one row per franchise, with details read out', () async {
    await addEntry('s1', 'completed', malId: 1, franchise: 1, json: season1);
    await addEntry('s2', 'watching', malId: 2, franchise: 1, json: season2);
    await addEntry('other', 'plan_to_watch', name: 'Saved name');
    final rows = await loadLibraryRows(databases, TitleLanguage.romaji);
    expect(rows, hasLength(2));
    final frieren = rows.firstWhere((row) => row.isFranchise);
    expect(frieren.entryId, 's2');
    expect(frieren.name, 'Sousou no Frieren 2nd Season');
    expect((frieren.seasonsDone, frieren.seasonsTotal), (1, 2));
    expect(frieren.episodes, 10);
    expect(frieren.mediaType, 'tv');
    final other = rows.firstWhere((row) => !row.isFranchise);
    expect((other.name, other.isNotLinked), ('Saved name', true));
  });

  test('a placeholder link is ignored until the scan rebuilds it', () async {
    await addEntry(
      'a',
      'watching',
      malId: 1,
      franchise: 1,
      placeholder: true,
      json: season1,
    );
    await addEntry(
      'b',
      'watching',
      malId: 2,
      franchise: 1,
      placeholder: true,
      json: season2,
    );
    expect(
      await loadLibraryRows(databases, TitleLanguage.romaji),
      hasLength(2),
    );
  });

  test('the title follows the language, falling back to romaji', () async {
    await addEntry('a', 'watching', malId: 1, json: season1);
    await addEntry('b', 'watching', malId: 2, json: season2);
    Future<Map<String, String>> names(TitleLanguage language) async => {
      for (final row in await loadLibraryRows(databases, language))
        row.entryId: row.name,
    };
    expect((await names(TitleLanguage.english))['a'], 'Frieren');
    expect((await names(TitleLanguage.japanese))['a'], '葬送のフリーレン');
    expect(
      (await names(TitleLanguage.english))['b'],
      'Sousou no Frieren 2nd Season',
    );
  });

  test('a linked entry with no details yet is loading', () async {
    await addEntry('a', 'watching', malId: 1, name: 'Saved');
    final row = (await loadLibraryRows(databases, TitleLanguage.romaji)).single;
    expect(
      (row.isLoadingDetails, row.isNotLinked, row.name),
      (true, false, 'Saved'),
    );
  });

  test('the title language is read from the settings', () async {
    final record = databases.record;
    expect(await readTitleLanguage(record), TitleLanguage.romaji);
    await record
        .into(record.setting)
        .insert(
          SettingCompanion.insert(key: 'title_language', value: 'english'),
        );
    expect(await readTitleLanguage(record), TitleLanguage.english);
  });

  test(
    'the test list: every entry is in exactly one row, and tabs add up',
    () async {
      await importOldDatabase(File(testListPath), databases);
      final entries = await loadLibraryEntries(
        databases,
        TitleLanguage.english,
      );
      final rows = await loadLibraryRows(databases, TitleLanguage.english);
      final covered = [for (final row in rows) ...row.entryIds];
      expect(covered.length, entries.length);
      expect(covered.toSet().length, entries.length);
      final counts = countTabs(rows);
      final perStatus = LibraryTab.values
          .where((tab) => tab != LibraryTab.all)
          .fold<int>(0, (sum, tab) => sum + counts[tab]!);
      expect(perStatus, rows.length);
      expect(
        counts[LibraryTab.all],
        rows.length - counts[LibraryTab.notInterested]!,
      );
    },
    skip: skipWithoutTestList,
  );
}
