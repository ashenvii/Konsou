import '../search/title_words.dart';
import 'entry_status.dart';
import 'library_row.dart';

/// The Library's status tabs.
enum LibraryTab {
  all,
  watching,
  planned,
  completed,
  onHold,
  dropped,
  notInterested,
}

/// The Library's sort orders.
enum LibrarySort { recent, title }

/// Whether a row belongs in a tab; All leaves out Not interested.
bool isInTab(LibraryRow row, LibraryTab tab) => switch (tab) {
  LibraryTab.all => row.status != EntryStatus.notInterested,
  LibraryTab.watching => row.status.isWatching,
  LibraryTab.planned => row.status == EntryStatus.planned,
  LibraryTab.completed => row.status == EntryStatus.completed,
  LibraryTab.onHold => row.status == EntryStatus.onHold,
  LibraryTab.dropped => row.status == EntryStatus.dropped,
  LibraryTab.notInterested => row.status == EntryStatus.notInterested,
};

/// Rows in a tab, plus any kept in view.
List<LibraryRow> filterRowsByTab(
  List<LibraryRow> rows,
  LibraryTab tab, {
  Set<String> keep = const {},
}) => [
  for (final row in rows)
    if (isInTab(row, tab) || keep.contains(row.entryId)) row,
];

/// Rows Find matches, or every row when Find is empty.
List<LibraryRow> filterRowsByFind(List<LibraryRow> rows, Set<String>? matches) {
  if (matches == null) return rows;
  return [
    for (final row in rows)
      if (row.entryIds.any(matches.contains)) row,
  ];
}

/// How many rows each tab has.
Map<LibraryTab, int> countTabs(List<LibraryRow> rows) => {
  for (final tab in LibraryTab.values) tab: filterRowsByTab(rows, tab).length,
};

// folding is the slow part of a sort that runs every rebuild, so keep it
final _foldedTitles = <String, String>{};

/// A title as sorting and the letter headings read it.
String foldTitle(String name) =>
    _foldedTitles[name] ??= foldWords(name).join(' ');

/// Rows in the chosen sort order.
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

/// A list view column the header bar sorts by. Status is not one: the tab
/// already sorts statuses apart.
enum ListColumn { name, episodes, mal, yourScore }

/// A sort picked on the list's header bar, over the sort menu's.
typedef ColumnSort = ({ListColumn column, bool descending});

/// The sort the menu's [sort] already shows on the header bar: A to Z is the
/// name column, ascending.
ColumnSort? columnSortOf(LibrarySort sort) => switch (sort) {
  LibrarySort.title => (column: ListColumn.name, descending: false),
  LibrarySort.recent => null,
};

/// What a click on [column]'s caption does: ascending, then descending, then
/// off, back to the sort menu's choice. A column the menu already sorts
/// ascending starts at descending.
ColumnSort? nextColumnSort(
  ColumnSort? current,
  ListColumn column,
  LibrarySort menu,
) {
  final shown = current ?? columnSortOf(menu);
  if (shown == null || shown.column != column) {
    return (column: column, descending: false);
  }
  if (!shown.descending) return (column: column, descending: true);
  return null;
}

/// [rows] in [sort]'s order. A title with no value for the column (no MAL
/// score, not scored) goes last either way; ties go A to Z.
List<LibraryRow> sortRowsByColumn(List<LibraryRow> rows, ColumnSort sort) {
  int byTitle(LibraryRow first, LibraryRow second) {
    final byName = foldTitle(first.name).compareTo(foldTitle(second.name));
    return byName != 0 ? byName : first.entryId.compareTo(second.entryId);
  }

  num? valueOf(LibraryRow row) => switch (sort.column) {
    ListColumn.name => null,
    ListColumn.episodes => row.episodesWatched,
    ListColumn.mal => row.malScore,
    ListColumn.yourScore => row.score,
  };

  int compare(LibraryRow first, LibraryRow second) {
    if (sort.column == ListColumn.name) {
      final byName = byTitle(first, second);
      return sort.descending ? -byName : byName;
    }
    final a = valueOf(first);
    final b = valueOf(second);
    if (a == null || b == null) {
      if (a == b) return byTitle(first, second);
      return a == null ? 1 : -1;
    }
    final byValue = sort.descending ? b.compareTo(a) : a.compareTo(b);
    return byValue != 0 ? byValue : byTitle(first, second);
  }

  return [...rows]..sort(compare);
}

/// Grid or list.
enum LibraryLayout { grid, list }
