import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/search/entry_search.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_entry_search_test');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<void> addEntry(
    String id, {
    String? name,
    int? malId,
    int changedAt = 1,
  }) async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: id,
            name: Value(name),
            status: 'watching',
            addedAt: 1,
            progressChangedAt: changedAt,
          ),
        );
    if (malId == null) return;
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

  Future<void> addDetail(int malId, String json) {
    final details = databases.details;
    return details
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

  Future<EntrySearch> loadedSearch() async {
    final search = EntrySearch(databases);
    await search.refresh();
    return search;
  }

  test(
    'finds a linked entry by its MAL titles and a not-linked one by name',
    () async {
      await addEntry('frieren', malId: 52991);
      await addDetail(
        52991,
        '{"title": "Sousou no Frieren", "alternative_titles": '
        '{"en": "Frieren: Beyond Journey\'s End"}}',
      );
      await addEntry('rick', name: 'Rick and Morty');
      final search = await loadedSearch();
      expect(search.findEntries('beyond journey'), ['frieren']);
      expect(search.findEntries('rick morty'), ['rick']);
    },
  );

  test('a misspelled word still finds the entry', () async {
    await addEntry('frieren', malId: 52991);
    await addDetail(52991, '{"title": "Sousou no Frieren"}');
    final search = await loadedSearch();
    expect(search.findEntries('frieran'), ['frieren']);
  });

  test('titles not on the list never come back', () async {
    await addEntry('frieren', malId: 52991);
    await addDetail(52991, '{"title": "Sousou no Frieren"}');
    await addDetail(56885, '{"title": "Sousou no Frieren 2nd Season"}');
    final search = await loadedSearch();
    expect(search.findEntries('frieren'), ['frieren']);
  });

  test('nothing is found before the first refresh', () async {
    await addEntry('rick', name: 'Rick and Morty');
    expect(EntrySearch(databases).findEntries('rick'), isEmpty);
  });

  test('refresh picks up an entry added after the last one', () async {
    final search = await loadedSearch();
    await addEntry('rick', name: 'Rick and Morty');
    expect(search.findEntries('rick'), isEmpty);
    await search.refresh();
    expect(search.findEntries('rick'), ['rick']);
  });

  test('recent entries are the last changed, newest first', () async {
    for (var number = 1; number <= 7; number++) {
      await addEntry('e$number', changedAt: number * 10);
    }
    final search = await loadedSearch();
    expect(await search.findRecent(), ['e7', 'e6', 'e5', 'e4', 'e3']);
    expect(await search.findRecent(count: 2), ['e7', 'e6']);
  });

  test(
    'a score change moves an entry to the front of the recent ones',
    () async {
      await addEntry('old', changedAt: 10);
      await addEntry('new', changedAt: 20);
      final record = databases.record;
      await (record.update(record.entry)
            ..where((row) => row.entryId.equals('old')))
          .write(const EntryCompanion(scoreChangedAt: Value(30)));
      final search = await loadedSearch();
      expect(await search.findRecent(), ['old', 'new']);
    },
  );

  test('MAL pages already linked to an entry are dropped', () async {
    await addEntry('frieren', malId: 52991);
    final search = await loadedSearch();
    expect(await search.dropListed([52991, 56885, 1]), [56885, 1]);
    expect(await search.dropListed([]), isEmpty);
  });
}
