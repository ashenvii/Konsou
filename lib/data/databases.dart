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

  if (discardBrokenDetails(detailsPath)) {
    stderr.writeln('details.db failed its check and was rebuilt');
  }
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

/// details.db holds only what can be fetched again, so a copy that fails the
/// database's own check is deleted (with its side files) and rebuilt, instead
/// of leaving the Library unreadable. Returns true when it was discarded. The
/// record, konsou.db, is never touched.
bool discardBrokenDetails(String path) {
  if (!File(path).existsSync()) return false;
  var broken = false;
  try {
    final raw = sqlite3.open(path);
    try {
      broken = raw.select('PRAGMA quick_check').first.values.first != 'ok';
    } finally {
      raw.close();
    }
  } on SqliteException {
    broken = true;
  }
  if (!broken) return false;
  for (final suffix in ['', '-wal', '-shm']) {
    final file = File('$path$suffix');
    if (file.existsSync()) file.deleteSync();
  }
  return true;
}

void _setUp(Database raw) {
  raw.execute('PRAGMA journal_mode = WAL');
  raw.execute('PRAGMA foreign_keys = ON');
}
