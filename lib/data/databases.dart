import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import 'details_database.dart';
import 'record_database.dart';

class Databases {
  Databases(this.record, this.details);

  final RecordDatabase record;
  final DetailsDatabase details;

  Future<void> close() async {
    await record.close();
    await details.close();
  }
}

/// Opens konsou.db and details.db in [folder]. The record connection has
/// details.db attached as `details`, so one query can read both files.
Future<Databases> openDatabases(Directory folder) async {
  final separator = Platform.pathSeparator;
  final recordFile = File('${folder.path}${separator}konsou.db');
  final detailsPath = '${folder.path}${separator}details.db';

  final details = DetailsDatabase(
    NativeDatabase.createInBackground(File(detailsPath), setup: _setUp),
  );
  // the tables must exist before the record connection attaches the file
  await details.customSelect('SELECT 1').get();

  final record = RecordDatabase(
    NativeDatabase.createInBackground(
      recordFile,
      setup: (raw) {
        _setUp(raw);
        raw.execute('ATTACH DATABASE ? AS details', [detailsPath]);
      },
    ),
  );
  await record.customSelect('SELECT 1').get();
  return Databases(record, details);
}

void _setUp(Database raw) {
  raw.execute('PRAGMA journal_mode = WAL');
  raw.execute('PRAGMA foreign_keys = ON');
}
