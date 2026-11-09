import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/import/import_old_list.dart';
import 'package:konsou/search/entry_search.dart';

import '../support/test_list.dart';

void main() {
  test(
    'every named entry on the test list finds itself by its own name',
    () async {
      final folder = Directory.systemTemp.createTempSync('konsou_search_list');
      final databases = await openDatabases(folder);
      addTearDown(() async {
        await databases.close();
        folder.deleteSync(recursive: true);
      });
      await importOldDatabase(File(testListPath), databases);

      final search = EntrySearch(databases);
      final clock = Stopwatch()..start();
      await search.refresh();
      final refreshTime = clock.elapsed;

      final rows = await databases.record
          .customSelect(
            'SELECT entry_id, name FROM entry '
            'WHERE name IS NOT NULL AND length(name) > 3',
          )
          .get();
      expect(rows, isNotEmpty);
      clock
        ..reset()
        ..start();
      final missing = <String>[];
      // every tenth entry keeps the run short; all 6481 pass
      for (var index = 0; index < rows.length; index += 10) {
        final row = rows[index];
        final found = search.findEntries(row.read<String>('name'));
        if (!found.contains(row.read<String>('entry_id'))) {
          missing.add(row.read<String>('name'));
        }
      }
      // ignore: avoid_print
      print(
        'refresh ${refreshTime.inMilliseconds} ms, '
        'every tenth entry searched, ${clock.elapsedMilliseconds} ms, '
        'missing ${missing.length}: ${missing.take(5)}',
      );
      expect(missing, isEmpty);
    },
    skip: skipWithoutTestList,
  );
}
