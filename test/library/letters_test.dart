import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/letters.dart';
import 'package:konsou/library/library_row.dart';

LibraryRow row(String name) => LibraryRow(
  current: LibraryEntry(
    entryId: name,
    name: name,
    status: EntryStatus.completed,
    episodesWatched: 0,
    addedAt: 0,
    changedAt: 0,
  ),
  entryIds: [name],
  addedAt: 0,
  changedAt: 0,
);

void main() {
  test('a title sorts under its first letter, accents folded', () {
    expect(readLetter('Frieren'), 'F');
    expect(readLetter('frieren'), 'F');
    expect(readLetter('Éclair'), 'E');
    expect(readLetter('Ōkami'), 'O');
  });

  test('digits, symbols, other scripts and nothing go under #', () {
    expect(readLetter('86 Eighty-Six'), '#');
    expect(readLetter('.hack//Sign'), 'H');
    expect(readLetter('進撃の巨人'), '#');
    expect(readLetter(''), '#');
  });

  test('groups come in heading order and empty ones are left out', () {
    final groups = groupByLetter([
      row('1'),
      row('Ao'),
      row('Bleach'),
      row('Bo'),
    ]);
    expect([for (final g in groups) g.letter], ['#', 'A', 'B']);
    expect(groups.last.rows.length, 2);
  });
}
