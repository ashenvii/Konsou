import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/import/import_old_list.dart';
import 'package:konsou/sync/local_record.dart';
import 'package:konsou/sync/merge_records.dart';
import 'package:konsou/sync/sync_record.dart';

import '../support/sync_rows.dart';
import '../support/test_list.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_local_record_test');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<Object?> readValue(String sql) async {
    final row = await databases.record.customSelect(sql).getSingle();
    return row.data.values.single;
  }

  test('only the not-linked names of the test list go into the file', () async {
    await importOldDatabase(File(testListPath), databases);
    final local = await readLocalRecord(databases.record);

    expect(local.entries, hasLength(6499));
    expect(local.completions, hasLength(3175));
    expect(local.alerts, hasLength(875));
    expect(local.toJson(), isNot(contains('"name":"ONE PIECE"')));
    final named = local.entries.where((entry) => entry['name'] != null);
    expect(named, hasLength(38));
    expect(
      named.every(
        (entry) => (entry['references'] as List).every(
          (reference) => (reference as Map)['provider'] != 'mal',
        ),
      ),
      isTrue,
    );
  }, skip: skipWithoutTestList);

  test(
    'the test list merged with itself is unchanged, shared pages and all',
    () async {
      await importOldDatabase(File(testListPath), databases);
      final local = await readLocalRecord(databases.record);
      final merged = mergeRecords(local, local);

      expect(merged.toJson(), local.toJson());
      expect(merged.aliases, isEmpty);
      final onPage38431 = merged.entries.where(
        (entry) => (entry['references'] as List).any(
          (reference) => (reference as Map)['provider_id'] == 38431,
        ),
      );
      expect(onPage38431, hasLength(2));
    },
    skip: skipWithoutTestList,
  );

  test('a phone with new ids for titles on the list folds them in', () async {
    await importOldDatabase(File(testListPath), databases);
    final local = await readLocalRecord(databases.record);
    int? readMalPage(Row entry) {
      for (final reference in entry['references'] as List) {
        final map = reference as Map;
        if (map['provider'] == 'mal') return map['provider_id'] as int;
      }
      return null;
    }

    final pages = local.entries.map(readMalPage).whereType<int>().toList();
    final single = pages.firstWhere(
      (page) => pages.where((other) => other == page).length == 1,
    );
    final phone = SyncRecord(
      entries: [
        buildEntry('phone-single', addedAt: 1, malId: single),
        buildEntry('phone-shared', addedAt: 1, malId: 38431),
      ],
    );

    final merged = mergeRecords(local, phone);

    expect(merged.entries, hasLength(6499 + 1));
    expect(merged.aliases.single['entry_id'], 'phone-single');
    expect(
      merged.entries.where((entry) => readMalPage(entry) == 38431),
      hasLength(3),
    );
  }, skip: skipWithoutTestList);

  test('writing the test list back changes nothing', () async {
    await importOldDatabase(File(testListPath), databases);
    final before = await readLocalRecord(databases.record);
    await writeLocalRecord(databases.record, before);

    expect((await readLocalRecord(databases.record)).toJson(), before.toJson());
    expect(
      await readValue("SELECT name FROM entry WHERE entry_id = 'legacy-21'"),
      'ONE PIECE',
    );
    expect(
      await readValue('SELECT count(*) FROM completion WHERE name IS NULL'),
      0,
    );
  }, skip: skipWithoutTestList);

  test('a merge from another device is written with names kept', () async {
    final record = databases.record;
    await writeLocalRecord(
      record,
      SyncRecord(entries: [buildEntry('pc', addedAt: 100, malId: 7)]),
    );
    await record.customStatement("UPDATE entry SET name = 'Frieren'");
    await record.customStatement(
      "INSERT INTO setting (\"key\", value) VALUES ('window', 'big')",
    );

    final drive = SyncRecord(
      entries: [
        buildEntry('phone', addedAt: 50, malId: 7, episodes: 3, progressAt: 9),
      ],
      completions: [buildCompletion('phone', 0, 70)],
    );
    final merged = mergeRecords(await readLocalRecord(record), drive);
    await writeLocalRecord(record, merged);

    expect((await readLocalRecord(record)).toJson(), merged.toJson());
    expect(await readValue('SELECT entry_id FROM entry'), 'phone');
    expect(await readValue('SELECT name FROM entry'), 'Frieren');
    expect(await readValue('SELECT name FROM completion'), 'Frieren');
    expect(await readValue('SELECT alias_id FROM entry_alias'), 'pc');
    expect(
      await readValue("SELECT value FROM setting WHERE \"key\" = 'window'"),
      'big',
    );
  });

  test('a not-linked name fills an empty one and never erases one', () async {
    final record = databases.record;
    await writeLocalRecord(
      record,
      SyncRecord(
        entries: [
          buildEntry('unlinked', name: 'Rick and Morty: The Anime'),
          buildEntry('linked', malId: 52991),
        ],
      ),
    );
    await record.customStatement(
      "UPDATE entry SET name = 'Frieren' WHERE entry_id = 'linked'",
    );
    final local = await readLocalRecord(record);
    expect(local.entries.map((entry) => entry['name']), [
      null,
      'Rick and Morty: The Anime',
    ]);

    await writeLocalRecord(record, local);
    expect(
      await readValue("SELECT name FROM entry WHERE entry_id = 'linked'"),
      'Frieren',
    );
    expect(
      await readValue("SELECT name FROM entry WHERE entry_id = 'unlinked'"),
      'Rick and Morty: The Anime',
    );
  });
}
