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

enum LibrarySort { recent, title }

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

/// The rows of [tab]. A row in [keep] stays in view even after an edit moved
/// it out of the tab, so the change can be seen.
List<LibraryRow> rowsInTab(
  List<LibraryRow> rows,
  LibraryTab tab, {
  Set<String> keep = const {},
}) => [
  for (final row in rows)
    if (isInTab(row, tab) || keep.contains(row.entryId)) row,
];

Map<LibraryTab, int> countTabs(List<LibraryRow> rows) => {
  for (final tab in LibraryTab.values) tab: rowsInTab(rows, tab).length,
};

/// Recent starts with the newest change; Title runs A to Z. Ties fall back
/// to the title, then the entry, so the order never shifts between redraws.
List<LibraryRow> sortRows(List<LibraryRow> rows, LibrarySort sort) {
  // fold each title once, not on every comparison
  final keys = {for (final row in rows) row: foldWords(row.name).join(' ')};
  int byTitle(LibraryRow first, LibraryRow second) {
    final byName = keys[first]!.compareTo(keys[second]!);
    return byName != 0 ? byName : first.entryId.compareTo(second.entryId);
  }

  int compare(LibraryRow first, LibraryRow second) {
    final byKey = switch (sort) {
      LibrarySort.recent => second.changedAt.compareTo(first.changedAt),
      LibrarySort.title => 0,
    };
    return byKey != 0 ? byKey : byTitle(first, second);
  }

  return [...rows]..sort(compare);
}

/// How the Library draws its rows. Remembered between runs.
enum LibraryLayout { grid, list }
