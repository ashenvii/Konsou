import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory folder;
  late String path;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('konsou_broken_details');
    path = '${folder.path}${Platform.pathSeparator}details.db';
  });

  tearDown(() => folder.deleteSync(recursive: true));

  test('a healthy details file is left alone', () {
    sqlite3.open(path)
      ..execute('CREATE TABLE t (a)')
      ..execute('INSERT INTO t VALUES (1)')
      ..close();
    expect(discardBrokenDetails(path), isFalse);
    expect(File(path).existsSync(), isTrue);
  });

  test('a missing file is not a problem', () {
    expect(discardBrokenDetails(path), isFalse);
  });

  test('a file that is not a database is deleted', () {
    File(path).writeAsBytesSync(Uint8List.fromList(List.filled(9000, 7)));
    expect(discardBrokenDetails(path), isTrue);
    expect(File(path).existsSync(), isFalse);
  });

  test('a database with damaged pages is deleted with its side files', () {
    final raw = sqlite3.open(path)
      ..execute('PRAGMA journal_mode = DELETE')
      ..execute('CREATE TABLE t (a TEXT)');
    for (var i = 0; i < 2000; i++) {
      raw.execute('INSERT INTO t VALUES (?)', ['row $i ${'x' * 200}']);
    }
    raw.close();
    final bytes = File(path).readAsBytesSync();
    // scribble over a page in the middle of the file
    for (var i = 4096 * 20; i < 4096 * 21; i++) {
      bytes[i] = 0xFF;
    }
    File(path).writeAsBytesSync(bytes);
    File('$path-wal').writeAsBytesSync([]);
    expect(discardBrokenDetails(path), isTrue);
    expect(File(path).existsSync(), isFalse);
    expect(File('$path-wal').existsSync(), isFalse);
  });

  test('opening the databases rebuilds a broken details file', () async {
    File(path).writeAsBytesSync(Uint8List.fromList(List.filled(9000, 7)));
    final databases = await openDatabases(folder);
    addTearDown(databases.close);
    final tables = await databases.details
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    expect(tables.map((row) => row.read<String>('name')), contains('detail'));
  });
}
