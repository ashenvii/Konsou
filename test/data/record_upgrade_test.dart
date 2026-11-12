import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/record_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'a version 1 record takes the new alert type and keeps its alerts',
    () async {
      final folder = Directory.systemTemp.createTempSync('konsou_upgrade');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}${Platform.pathSeparator}konsou.db');
      sqlite3.open(file.path)
        ..execute(
          '''
        CREATE TABLE alert (
          entry_id TEXT NOT NULL,
          related_provider TEXT NOT NULL CHECK (related_provider IN ('mal', 'anilist')),
          related_provider_id INTEGER NOT NULL,
          type TEXT NOT NULL CHECK (type IN (
            'sequel', 'side_story', 'spin_off', 'movie', 'started_airing')),
          seen BOOLEAN NOT NULL DEFAULT FALSE,
          dismissed BOOLEAN NOT NULL DEFAULT FALSE,
          created_at INTEGER NOT NULL,
          PRIMARY KEY (entry_id, related_provider, related_provider_id, type))''',
        )
        ..execute("INSERT INTO alert VALUES ('a', 'mal', 7, 'sequel', 0, 0, 1)")
        ..execute('PRAGMA user_version = 1')
        ..close();

      final record = RecordDatabase(NativeDatabase(file));
      addTearDown(record.close);
      await record.customStatement(
        "INSERT INTO alert VALUES ('a', 'mal', 8, 'earlier_unmarked', 0, 0, 2)",
      );
      expect(await record.select(record.alert).get(), hasLength(2));
    },
  );
}
