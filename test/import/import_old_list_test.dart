import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/import/import_old_list.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import '../support/test_list.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_import_test');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  Future<int> count(String sql) async {
    final row = await databases.record.customSelect(sql).getSingle();
    return row.data.values.single as int;
  }

  test('a record that already has entries is refused', () async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: 'abc',
            status: 'watching',
            addedAt: 1,
            updatedAt: 1,
          ),
        );
    await expectLater(
      importOldDatabase(File('${folder.path}/old.db'), databases),
      throwsA(isA<ImportRefused>()),
    );
    expect(await count('SELECT count(*) FROM entry'), 1);
  });

  test('a file that is not a database is refused', () async {
    final notADatabase = File('${folder.path}/notes.txt')
      ..writeAsStringSync('just some text, long enough to fill a header');
    await expectLater(
      importOldDatabase(notADatabase, databases),
      throwsA(isA<ImportRefused>()),
    );
  });

  group('the test list', () {
    final testList = File(testListPath);
    final skip = skipWithoutTestList;

    test('imports with every count from SCHEMA.md', () async {
      final before = testList.readAsBytesSync();

      final report = await importOldDatabase(testList, databases);

      expect(report.entries, 6499);
      expect(report.completions, 3175);
      expect(report.deletions, 1);
      expect(report.alerts, 875);
      expect(report.scoresRounded, 0);
      expect(report.timestampsFixed, 50);
      expect(report.rowsSkipped, 0);

      expect(await count('SELECT count(*) FROM entry'), 6499);
      expect(await count('SELECT count(*) FROM completion'), 3175);
      expect(await count('SELECT count(*) FROM deletion'), 1);
      expect(await count('SELECT count(score) FROM entry'), 1396);
      expect(await count('SELECT count(notes) FROM entry'), 667);
      expect(await count('SELECT count(plan_rank) FROM entry'), 12);
      expect(
        await count(
          "SELECT count(*) FROM entry_reference WHERE provider = 'mal'",
        ),
        6461,
      );
      expect(
        await count(
          "SELECT count(*) FROM entry_reference WHERE provider = 'anilist'",
        ),
        6499,
      );
      expect(await count('SELECT count(*) FROM alert'), 875);
      expect(
        await count(
          'SELECT count(*) FROM details.franchise_link WHERE is_placeholder',
        ),
        6499,
      );
      expect(
        await count(
          'SELECT count(*) FROM entry WHERE updated_at < 100000000000',
        ),
        0,
      );
      expect(
        await count(
          'SELECT count(*) FROM alert WHERE created_at < 100000000000',
        ),
        0,
      );
      expect(await count("SELECT count(*) FROM setting"), 1);
      expect(testList.readAsBytesSync(), before);
    }, skip: skip);

    test('one row comes over with its values and its seconds fixed', () async {
      await importOldDatabase(testList, databases);
      final row = await databases.record.customSelect('''
        SELECT entry.*, franchise_link.franchise_provider_id
        FROM entry JOIN details.franchise_link USING (entry_id)
        WHERE entry_id = 'legacy-21'
      ''').getSingle();
      expect(row.data, {
        'entry_id': 'legacy-21',
        'name': 'ONE PIECE',
        'status': 'watching',
        'episodes_watched': 235,
        'score': null,
        'notes': null,
        'plan_rank': null,
        'added_at': 1669585154282,
        'updated_at': 1793390531000,
        'started_at': 1670276354282,
        'franchise_provider_id': 167404,
      });
    }, skip: skip);

    // v0.7.0, the last release, stopped at old migration 9
    test('a version 9 copy imports with its completions rebuilt', () async {
      final v9 = testList.copySync('${folder.path}/v9.db');
      final db = raw.sqlite3.open(v9.path);
      db.execute('ALTER TABLE anime_list DROP COLUMN plan_rank');
      db.execute('DROP TABLE completion_log');
      db.execute('DELETE FROM _sqlx_migrations WHERE version >= 10');
      db.close();

      final report = await importOldDatabase(v9, databases);

      expect(report.entries, 6499);
      // worked out by hand from old migration 12's rule on the test list
      expect(report.completions, 3175);
      expect(
        await count('SELECT count(*) FROM completion WHERE is_estimated'),
        3175,
      );
      expect(await count('SELECT count(plan_rank) FROM entry'), 0);
    }, skip: skip);

    test('a failure halfway leaves the record empty', () async {
      final broken = testList.copySync('${folder.path}/broken.db');
      final db = raw.sqlite3.open(broken.path);
      db.execute('ALTER TABLE notifications RENAME TO checked');
      db.execute('CREATE TABLE notifications AS SELECT * FROM checked WHERE 0');
      db.execute(
        "INSERT INTO notifications (source_id, related_id, type, related_title, "
        "related_status, seen, dismissed, created_at) "
        "VALUES (21, 1, 'bogus', 'x', 'x', 0, 0, 1)",
      );
      db.close();

      await expectLater(
        importOldDatabase(broken, databases),
        throwsA(
          predicate(
            (Object error) =>
                '$error'.contains('CHECK constraint failed: type'),
          ),
        ),
      );

      expect(await count('SELECT count(*) FROM entry'), 0);
      expect(await count('SELECT count(*) FROM completion'), 0);
      expect(await count('SELECT count(*) FROM details.franchise_link'), 0);
    }, skip: skip);

    test('a second run is refused and writes nothing', () async {
      await importOldDatabase(testList, databases);
      await expectLater(
        importOldDatabase(testList, databases),
        throwsA(isA<ImportRefused>()),
      );
      expect(await count('SELECT count(*) FROM entry'), 6499);
    }, skip: skip);
  });

  group('an old "Export list" file', () {
    // hand-written in the shape the old app exported: an array of list rows
    const export = '''
[
  {"anilist_id": 154587, "mal_id": 52991, "title_romaji": "Sousou no Frieren",
   "title_english": "Frieren: Beyond Journey's End", "status": "completed",
   "episodes_watched": 28, "score": 9.5, "added_at": 1700000000000,
   "updated_at": 1700000000000, "completed_at": 1710000000000,
   "rewatch_count": 1, "has_dub": true},
  {"anilist_id": 1, "title_romaji": "Cowboy Bebop", "status": "plan_to_watch",
   "episodes_watched": 0, "added_at": 1700000000000, "updated_at": 1700000000},
  {"anilist_id": 2, "title_romaji": "Odd", "status": "finished",
   "episodes_watched": 0, "added_at": 1, "updated_at": 1},
  "not a row"
]''';

    test('imports through the same path as a database file', () async {
      final report = await importExportJson(export, databases);

      expect(report.entries, 2);
      // completed once and rewatched once, rebuilt as two estimated watches
      expect(report.completions, 2);
      expect(report.scoresRounded, 1);
      expect(report.timestampsFixed, 1);
      expect(report.rowsSkipped, 2);
      expect(
        await count("SELECT score FROM entry WHERE entry_id = 'legacy-154587'"),
        10,
      );
      expect(
        await count("SELECT updated_at FROM entry WHERE entry_id = 'legacy-1'"),
        1700000000000,
      );
      expect(
        await count(
          "SELECT count(*) FROM entry_reference WHERE provider = 'mal'",
        ),
        1,
      );
    });

    test('a file that is not an export is refused', () async {
      await expectLater(
        importExportJson('{"entries": []}', databases),
        throwsA(isA<ImportRefused>()),
      );
    });
  });
}
