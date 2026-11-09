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
}
