import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/test_list.dart';

/// The counts step 3's importer has to reproduce, read from the old Tauri
/// file with the same sqlite the app ships.
void main() {
  test('the bundled sqlite reads the old list without writing to it', () {
    final db = sqlite3.open(testListPath, mode: OpenMode.readOnly);
    addTearDown(db.close);
    int count(String sql) => db.select(sql).single.values.single as int;

    expect(count('SELECT count(*) FROM anime_list'), 6499);
    expect(count('SELECT count(*) FROM completion_log'), 3175);
    expect(count('SELECT count(*) FROM list_tombstones'), 1);
    expect(count('SELECT count(score) FROM anime_list'), 1396);
    expect(count('SELECT count(notes) FROM anime_list'), 667);
    expect(count('SELECT count(plan_rank) FROM anime_list'), 12);
    expect(count('SELECT count(mal_id) FROM anime_list'), 6461);
    expect(count('SELECT count(*) FROM notifications'), 875);
    expect(
      () => db.execute('DELETE FROM list_tombstones'),
      throwsA(isA<SqliteException>()),
    );
  }, skip: skipWithoutTestList);
}
