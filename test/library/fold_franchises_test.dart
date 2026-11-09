import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/library/fold_franchises.dart';
import 'package:konsou/library/library_row.dart';

LibraryEntry entry(
  String id,
  String status, {
  int? franchise,
  String? date,
  bool extra = false,
  int? malId,
  bool details = true,
  int watched = 0,
  int changed = 1,
  int added = 1,
}) => LibraryEntry(
  entryId: id,
  name: 'Name $id',
  status: status,
  episodesWatched: watched,
  addedAt: added,
  changedAt: changed,
  malId: malId ?? 1,
  hasDetails: details,
  franchiseId: franchise,
  startDate: date,
  isExtra: extra,
);

LibraryRow only(List<LibraryEntry> entries) {
  final rows = foldFranchises(entries);
  expect(rows, hasLength(1));
  return rows.single;
}

void main() {
  test('an entry the scan has not placed is a row of its own', () {
    final rows = foldFranchises([
      entry('a', 'watching'),
      entry('b', 'plan_to_watch'),
    ]);
    expect(rows, hasLength(2));
    expect(rows.first.isFranchise, isFalse);
  });

  test('seasons of one franchise are one row that lists them all', () {
    final row = only([
      entry('s1', 'completed', franchise: 7, date: '2020-01-01'),
      entry('s2', 'watching', franchise: 7, date: '2021-01-01'),
    ]);
    expect(row.entryIds, unorderedEquals(['s1', 's2']));
  });

  test('the earliest season being watched stands for the franchise', () {
    expect(
      only([
        entry('s1', 'completed', franchise: 7, date: '2020'),
        entry('s2', 'watching', franchise: 7, date: '2021'),
        entry('s3', 'plan_to_watch', franchise: 7, date: '2022'),
      ]).entryId,
      's2',
    );
    expect(
      only([
        entry('s2', 'watching', franchise: 7, date: '2021'),
        entry('s3', 'rewatching', franchise: 7, date: '2022'),
      ]).entryId,
      's2',
    );
  });

  test('without one being watched, the earliest planned, then on hold', () {
    expect(
      only([
        entry('s1', 'completed', franchise: 7, date: '2020'),
        entry('s2', 'on_hold', franchise: 7, date: '2021'),
        entry('s3', 'plan_to_watch', franchise: 7, date: '2022'),
        entry('s4', 'plan_to_watch', franchise: 7, date: '2023'),
      ]).entryId,
      's3',
    );
    expect(
      only([
        entry('s1', 'completed', franchise: 7, date: '2020'),
        entry('s2', 'on_hold', franchise: 7, date: '2021'),
      ]).entryId,
      's2',
    );
  });

  test('all finished shows the last season, as completed', () {
    final row = only([
      entry('s1', 'completed', franchise: 7, date: '2020'),
      entry('s2', 'completed', franchise: 7, date: '2021'),
    ]);
    expect((row.entryId, row.status), ('s2', 'completed'));
  });

  test('dropped and not interested seasons count as finished', () {
    expect(
      only([
        entry('s1', 'dropped', franchise: 7, date: '2020'),
        entry('s2', 'plan_to_watch', franchise: 7, date: '2021'),
      ]).entryId,
      's2',
    );
    expect(
      only([
        entry('s1', 'completed', franchise: 7, date: '2020'),
        entry('s2', 'dropped', franchise: 7, date: '2021'),
      ]).entryId,
      's2',
    );
  });

  test('undated seasons come last, then the older entry', () {
    expect(
      only([
        entry('a', 'plan_to_watch', franchise: 7),
        entry('b', 'plan_to_watch', franchise: 7, date: '2021'),
      ]).entryId,
      'b',
    );
    expect(
      only([
        entry('a', 'plan_to_watch', franchise: 7, date: '2021', added: 5),
        entry('b', 'plan_to_watch', franchise: 7, date: '2021', added: 2),
      ]).entryId,
      'b',
    );
  });

  test('a season count shows for more than one story season on the list', () {
    final row = only([
      entry('s1', 'completed', franchise: 7, date: '2020'),
      entry('s2', 'watching', franchise: 7, date: '2021'),
    ]);
    expect((row.seasonsDone, row.seasonsTotal), (1, 2));
    expect(row.isFranchise, isTrue);
    final single = only([entry('s1', 'completed', franchise: 7)]);
    expect(single.seasonsTotal, isNull);
  });

  test('extras ride along but are not counted or chosen', () {
    final row = only([
      entry('s1', 'completed', franchise: 7, date: '2020'),
      entry('s2', 'watching', franchise: 7, date: '2021'),
      entry('ova', 'plan_to_watch', franchise: 7, date: '2019', extra: true),
    ]);
    expect((row.entryId, row.seasonsTotal), ('s2', 2));
    expect(row.entryIds, contains('ova'));
  });

  test('a franchise with only extras on the list is still one row', () {
    final row = only([
      entry('ova', 'plan_to_watch', franchise: 7, extra: true),
    ]);
    expect(row.entryId, 'ova');
    expect(row.seasonsTotal, isNull);
  });

  test('the row takes the newest change and newest add of the franchise', () {
    final row = only([
      entry(
        's1',
        'completed',
        franchise: 7,
        date: '2020',
        changed: 90,
        added: 3,
      ),
      entry(
        's2',
        'watching',
        franchise: 7,
        date: '2021',
        changed: 10,
        added: 8,
      ),
    ]);
    expect((row.changedAt, row.addedAt), (90, 8));
  });

  test('not linked and loading details are told apart', () {
    const notLinked = LibraryEntry(
      entryId: 'x',
      name: 'Saved name',
      status: 'watching',
      episodesWatched: 0,
      addedAt: 1,
      changedAt: 1,
    );
    expect(only([notLinked]).isNotLinked, isTrue);
    expect(
      only([entry('y', 'watching', details: false)]).isLoadingDetails,
      isTrue,
    );
    expect(only([entry('z', 'watching')]).isLoadingDetails, isFalse);
  });

  test('the answer does not depend on the order entries come in', () {
    final entries = [
      entry('s1', 'completed', franchise: 7, date: '2020'),
      entry('s2', 'watching', franchise: 7, date: '2021'),
      entry('s3', 'plan_to_watch', franchise: 7, date: '2022'),
    ];
    expect(only(entries.reversed.toList()).entryId, only(entries).entryId);
  });
}
