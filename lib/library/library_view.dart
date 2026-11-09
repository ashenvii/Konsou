import '../search/title_words.dart';
import 'entry_status.dart';
import 'library_row.dart';

enum LibraryTab {
  all,
  watching,
  planned,
  completed,
  onHold,
  dropped,
  notInterested,
}

enum LibrarySort { recent, title, score, added }

/// Whether a row shows in [tab]. All holds everything but Not interested;
/// Watching holds Rewatching too.
bool isInTab(LibraryRow row, LibraryTab tab) => switch (tab) {
  LibraryTab.all => row.status != 'not_interested',
  LibraryTab.watching => watchingStatuses.contains(row.status),
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
  int byTitle(LibraryRow first, LibraryRow second) {
    final byName = foldWords(first.name)
        .join(' ')
        .compareTo(foldWords(second.name).join(' '));
    return byName != 0 ? byName : first.entryId.compareTo(second.entryId);
  }

  int compare(LibraryRow first, LibraryRow second) {
    final byKey = switch (sort) {
      LibrarySort.recent => second.changedAt.compareTo(first.changedAt),
      LibrarySort.added => second.addedAt.compareTo(first.addedAt),
      LibrarySort.score => _byScore(first, second),
      LibrarySort.title => 0,
    };
    return byKey != 0 ? byKey : byTitle(first, second);
  }

  return [...rows]..sort(compare);
}

/// Highest score first, unscored last.
int _byScore(LibraryRow first, LibraryRow second) {
  final firstScore = first.score;
  final secondScore = second.score;
  if (firstScore == secondScore) return 0;
  if (firstScore == null) return 1;
  if (secondScore == null) return -1;
  return secondScore.compareTo(firstScore);
}
