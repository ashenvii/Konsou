import '../search/title_words.dart';
import 'library_row.dart';

/// Whether a row shows in [tab]. All holds everything but Not interested;
/// Watching holds Rewatching too.
bool isInTab(LibraryRow row, LibraryTab tab) => switch (tab) {
  LibraryTab.all => row.status != 'not_interested',
  LibraryTab.watching => row.status == 'watching' || row.status == 'rewatching',
  LibraryTab.planned => row.status == 'plan_to_watch',
  LibraryTab.completed => row.status == 'completed',
  LibraryTab.onHold => row.status == 'on_hold',
  LibraryTab.dropped => row.status == 'dropped',
  LibraryTab.notInterested => row.status == 'not_interested',
};

List<LibraryRow> rowsInTab(List<LibraryRow> rows, LibraryTab tab) => [
  for (final row in rows)
    if (isInTab(row, tab)) row,
];

Map<LibraryTab, int> countTabs(List<LibraryRow> rows) => {
  for (final tab in LibraryTab.values) tab: rowsInTab(rows, tab).length,
};

/// Recent, Added and Score start with the newest or highest; Title runs
/// A to Z. Ties fall back to the title, then the entry, so the order never
/// shifts between redraws.
List<LibraryRow> sortRows(List<LibraryRow> rows, LibrarySort sort) {
  int byTitle(LibraryRow a, LibraryRow b) {
    final byName = foldWords(a.name)
        .join(' ')
        .compareTo(foldWords(b.name).join(' '));
    return byName != 0 ? byName : a.entryId.compareTo(b.entryId);
  }

  int compare(LibraryRow a, LibraryRow b) {
    final byKey = switch (sort) {
      LibrarySort.recent => b.changedAt.compareTo(a.changedAt),
      LibrarySort.added => b.addedAt.compareTo(a.addedAt),
      LibrarySort.score => _byScore(a, b),
      LibrarySort.title => 0,
    };
    return byKey != 0 ? byKey : byTitle(a, b);
  }

  return [...rows]..sort(compare);
}

/// Highest score first, unscored last.
int _byScore(LibraryRow a, LibraryRow b) {
  final aScore = a.score;
  final bScore = b.score;
  if (aScore == bScore) return 0;
  if (aScore == null) return 1;
  if (bScore == null) return -1;
  return bScore.compareTo(aScore);
}
