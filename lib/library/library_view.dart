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

bool isInTab(LibraryRow row, LibraryTab tab) => switch (tab) {
  LibraryTab.all => row.status != 'not_interested',
  LibraryTab.watching => watchingStatuses.contains(row.status),
  LibraryTab.planned => row.status == 'plan_to_watch',
  LibraryTab.completed => row.status == 'completed',
  LibraryTab.onHold => row.status == 'on_hold',
  LibraryTab.dropped => row.status == 'dropped',
  LibraryTab.notInterested => row.status == 'not_interested',
};

List<LibraryRow> rowsInTab(
  List<LibraryRow> rows,
  LibraryTab tab, {
  Set<String> keep = const {},
}) => [
  for (final row in rows)
    if (isInTab(row, tab) || keep.contains(row.entryId)) row,
];

List<LibraryRow> rowsMatching(List<LibraryRow> rows, Set<String>? matches) {
  if (matches == null) return rows;
  return [
    for (final row in rows)
      if (row.entryIds.any(matches.contains)) row,
  ];
}

Map<LibraryTab, int> countTabs(List<LibraryRow> rows) => {
  for (final tab in LibraryTab.values) tab: rowsInTab(rows, tab).length,
};

// folding is the slow part of a sort that runs every rebuild, so keep it
final _foldedTitles = <String, String>{};

String _foldedTitle(String name) =>
    _foldedTitles[name] ??= foldWords(name).join(' ');

List<LibraryRow> sortRows(List<LibraryRow> rows, LibrarySort sort) {
  // fold each title once, not on every comparison
  final keys = {for (final row in rows) row: _foldedTitle(row.name)};
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

enum LibraryLayout { grid, list }
