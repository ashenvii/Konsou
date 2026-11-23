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
  LibraryTab.all => row.status != EntryStatus.notInterested,
  LibraryTab.watching => row.status.isWatching,
  LibraryTab.planned => row.status == EntryStatus.planned,
  LibraryTab.completed => row.status == EntryStatus.completed,
  LibraryTab.onHold => row.status == EntryStatus.onHold,
  LibraryTab.dropped => row.status == EntryStatus.dropped,
  LibraryTab.notInterested => row.status == EntryStatus.notInterested,
};

List<LibraryRow> filterRowsByTab(
  List<LibraryRow> rows,
  LibraryTab tab, {
  Set<String> keep = const {},
}) => [
  for (final row in rows)
    if (isInTab(row, tab) || keep.contains(row.entryId)) row,
];

List<LibraryRow> filterRowsByFind(List<LibraryRow> rows, Set<String>? matches) {
  if (matches == null) return rows;
  return [
    for (final row in rows)
      if (row.entryIds.any(matches.contains)) row,
  ];
}

Map<LibraryTab, int> countTabs(List<LibraryRow> rows) => {
  for (final tab in LibraryTab.values) tab: filterRowsByTab(rows, tab).length,
};

// folding is the slow part of a sort that runs every rebuild, so keep it
final _foldedTitles = <String, String>{};

/// A title as sorting and the letter headings read it.
String foldTitle(String name) =>
    _foldedTitles[name] ??= foldWords(name).join(' ');

List<LibraryRow> sortRows(List<LibraryRow> rows, LibrarySort sort) {
  int byTitle(LibraryRow first, LibraryRow second) {
    final byName = foldTitle(first.name).compareTo(foldTitle(second.name));
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
