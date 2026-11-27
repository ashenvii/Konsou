import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/library/entry_status.dart';
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
    status: EntryStatus.parse(status),
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
    expect(ids(filterRowsByTab(rows, LibraryTab.watching)), ['a', 'b']);
    expect(ids(filterRowsByTab(rows, LibraryTab.planned)), ['c']);
    expect(ids(filterRowsByTab(rows, LibraryTab.completed)), ['d']);
    expect(ids(filterRowsByTab(rows, LibraryTab.onHold)), ['e']);
    expect(ids(filterRowsByTab(rows, LibraryTab.dropped)), ['f']);
    expect(ids(filterRowsByTab(rows, LibraryTab.notInterested)), ['g']);
  });

  test('All holds everything but Not interested', () {
    expect(ids(filterRowsByTab(rows, LibraryTab.all)), [
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

  test('Find keeps the rows with a matching entry; null keeps all', () {
    expect(ids(filterRowsByFind(rows, {'b', 'd'})), ['b', 'd']);
    expect(ids(filterRowsByFind(rows, const {})), isEmpty);
    expect(filterRowsByFind(rows, null), rows);
  });

  group('header bar sort', () {
    const recent = LibrarySort.recent;

    test('a click goes up, then down, then off', () {
      final up = nextColumnSort(null, ListColumn.mal, recent);
      expect(up, (column: ListColumn.mal, descending: false));
      final down = nextColumnSort(up, ListColumn.mal, recent);
      expect(down, (column: ListColumn.mal, descending: true));
      expect(nextColumnSort(down, ListColumn.mal, recent), isNull);
    });

    test('another column starts again at up', () {
      expect(
        nextColumnSort(
          (column: ListColumn.mal, descending: true),
          ListColumn.name,
          recent,
        ),
        (column: ListColumn.name, descending: false),
      );
    });

    test('A to Z already shows the name column up, so a click goes down', () {
      expect(columnSortOf(LibrarySort.title), (
        column: ListColumn.name,
        descending: false,
      ));
      expect(nextColumnSort(null, ListColumn.name, LibrarySort.title), (
        column: ListColumn.name,
        descending: true,
      ));
    });

    test('a column with no value sorts last both ways, ties A to Z', () {
      final rows = [
        row('c', 'watching', name: 'Charlie'),
        row('a', 'watching', name: 'Alpha', score: 7),
        row('b', 'watching', name: 'Bravo', score: 7),
        row('d', 'watching', name: 'Delta', score: 9),
      ];
      expect(
        ids(
          sortRowsByColumn(rows, (
            column: ListColumn.yourScore,
            descending: false,
          )),
        ),
        ['a', 'b', 'd', 'c'],
      );
      expect(
        ids(
          sortRowsByColumn(rows, (
            column: ListColumn.yourScore,
            descending: true,
          )),
        ),
        ['d', 'a', 'b', 'c'],
      );
    });

    test('the name column sorts A to Z and Z to A', () {
      final rows = [row('b', 'watching'), row('a', 'watching')];
      expect(
        ids(
          sortRowsByColumn(rows, (column: ListColumn.name, descending: true)),
        ),
        ['b', 'a'],
      );
    });
  });
}
