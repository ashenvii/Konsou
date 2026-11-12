import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/library/library_row.dart';

LibraryRow row(String id, {int episodes = 1}) => LibraryRow(
  current: LibraryEntry(
    entryId: id,
    name: 'T',
    status: 'watching',
    episodesWatched: episodes,
    addedAt: 1,
    changedAt: 1,
  ),
  entryIds: [id],
  addedAt: 1,
  changedAt: 1,
);

void main() {
  test('snapshots of the same rows are equal, so a reload changes nothing', () {
    expect(
      RowsSnapshot([row('a'), row('b')]),
      RowsSnapshot([row('a'), row('b')]),
    );
  });

  test('a changed row, or a different count, makes a different snapshot', () {
    expect(
      RowsSnapshot([row('a')]) == RowsSnapshot([row('a', episodes: 2)]),
      isFalse,
    );
    expect(
      RowsSnapshot([row('a')]) == RowsSnapshot([row('a'), row('b')]),
      isFalse,
    );
    expect(const RowsSnapshot(null) == RowsSnapshot([row('a')]), isFalse);
  });
}
