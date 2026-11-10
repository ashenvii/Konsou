import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/library/library_view.dart';

LibraryRow row(
  String id,
  String status, {
  String? name,
  int changed = 1,
  int added = 1,
  int? score,
}) => LibraryRow(
  current: LibraryEntry(
    entryId: id,
    name: name ?? id,
    status: status,
    episodesWatched: 0,
    addedAt: added,
    changedAt: changed,
    score: score,
  ),
  entryIds: [id],
  addedAt: added,
  changedAt: changed,
);

List<String> ids(List<LibraryRow> rows) => [for (final r in rows) r.entryId];

void main() {
  final rows = [
    row('a', 'watching'),
    row('b', 'rewatching'),
    row('c', 'plan_to_watch'),
    row('d', 'completed'),
    row('e', 'on_hold'),
    row('f', 'dropped'),
    row('g', 'not_interested'),
  ];

  test('each tab holds its status, Watching holds Rewatching too', () {
    expect(ids(rowsInTab(rows, LibraryTab.watching)), ['a', 'b']);
    expect(ids(rowsInTab(rows, LibraryTab.planned)), ['c']);
    expect(ids(rowsInTab(rows, LibraryTab.completed)), ['d']);
    expect(ids(rowsInTab(rows, LibraryTab.onHold)), ['e']);
    expect(ids(rowsInTab(rows, LibraryTab.dropped)), ['f']);
    expect(ids(rowsInTab(rows, LibraryTab.notInterested)), ['g']);
  });

  test('All holds everything but Not interested', () {
    expect(ids(rowsInTab(rows, LibraryTab.all)), [
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
    ]);
  });

  test('counts match the tabs', () {
    final counts = countTabs(rows);
    expect(counts[LibraryTab.all], 6);
    expect(counts[LibraryTab.watching], 2);
    expect(counts[LibraryTab.notInterested], 1);
  });

  test('recent: last changed first', () {
    final sorted = sortRows([
      row('a', 'watching', changed: 10),
      row('b', 'watching', changed: 30),
      row('c', 'watching', changed: 20),
    ], LibrarySort.recent);
    expect(ids(sorted), ['b', 'c', 'a']);
  });

  test('title: A to Z, ignoring case and punctuation', () {
    final sorted = sortRows([
      row('1', 'watching', name: 'Zetsuen'),
      row('2', 'watching', name: 'bleach'),
      row('3', 'watching', name: 'Re:Zero'),
    ], LibrarySort.title);
    expect(ids(sorted), ['2', '3', '1']);
  });

  test('equal rows keep one order however they arrive', () {
    final input = [
      row('a', 'watching', name: 'Same'),
      row('b', 'watching', name: 'Same'),
    ];
    expect(
      ids(sortRows(input.reversed.toList(), LibrarySort.recent)),
      ids(sortRows(input, LibrarySort.recent)),
    );
  });
}
