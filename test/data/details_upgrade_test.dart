import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/details_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'a version 1 details file gets the cover table and keeps its rows',
    () async {
      final folder = Directory.systemTemp.createTempSync('konsou_upgrade');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}${Platform.pathSeparator}details.db');
      sqlite3.open(file.path)
        ..execute(
          'CREATE TABLE gone_page (provider TEXT NOT NULL, '
          'provider_id INTEGER NOT NULL, checked_at INTEGER NOT NULL, '
          'PRIMARY KEY (provider, provider_id))',
        )
        ..execute("INSERT INTO gone_page VALUES ('mal', 7, 1)")
        ..execute('PRAGMA user_version = 1')
        ..close();

      final details = DetailsDatabase(NativeDatabase(file));
      addTearDown(details.close);
      final tables = await details
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      expect(tables.map((row) => row.read<String>('name')), contains('cover'));
      expect(await details.select(details.gonePage).get(), hasLength(1));
    },
  );

  test(
    'a details file stamped version 2 with the old cover_url column gets the '
    'medium and large columns and keeps its rows',
    () async {
      final folder = Directory.systemTemp.createTempSync('konsou_upgrade');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}${Platform.pathSeparator}details.db');
      sqlite3.open(file.path)
        ..execute('''
          CREATE TABLE detail (
            provider TEXT NOT NULL, provider_id INTEGER NOT NULL,
            fetched_at INTEGER NOT NULL, json TEXT NOT NULL,
            is_full BOOLEAN NOT NULL DEFAULT FALSE,
            cover_url TEXT GENERATED ALWAYS AS (COALESCE(
              json_extract(json, '\$.main_picture.large'),
              json_extract(json, '\$.main_picture.medium'))) VIRTUAL,
            PRIMARY KEY (provider, provider_id))''')
        ..execute(
          'CREATE TABLE cover (provider TEXT NOT NULL, '
          'provider_id INTEGER NOT NULL, size TEXT NOT NULL, '
          'url TEXT NOT NULL, file_name TEXT NOT NULL, bytes INTEGER NOT NULL, '
          'fetched_at INTEGER NOT NULL, shown_at INTEGER NOT NULL, '
          'PRIMARY KEY (provider, provider_id, size))',
        )
        ..execute(
          "INSERT INTO detail (provider, provider_id, fetched_at, json) "
          "VALUES ('mal', 5, 1, "
          '\'{"main_picture":{"medium":"m.jpg","large":"l.jpg"}}\')',
        )
        ..execute('PRAGMA user_version = 2')
        ..close();

      final details = DetailsDatabase(NativeDatabase(file));
      addTearDown(details.close);
      final row = await details
          .customSelect(
            'SELECT cover_medium_url AS m, cover_large_url AS l FROM detail',
          )
          .getSingle();
      expect(row.read<String>('m'), 'm.jpg');
      expect(row.read<String>('l'), 'l.jpg');
    },
  );
}
