import 'package:sqlite3/sqlite3.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the bundled sqlite has fts5', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    db.execute('CREATE VIRTUAL TABLE title_search USING fts5(name)');
    db.execute(
      "INSERT INTO title_search (name) VALUES ('Sousou no Frieren'), ('Bocchi the Rock')",
    );
    final rows = db.select(
      "SELECT name FROM title_search WHERE title_search MATCH 'frier*'",
    );
    expect(rows.map((r) => r['name']), ['Sousou no Frieren']);
  });
}
