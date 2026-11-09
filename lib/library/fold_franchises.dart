import 'library_row.dart';

const _watchingStatuses = {'watching', 'rewatching'};

/// One row per franchise, standing for the season the user is on, and one row
/// for each entry the scan has not placed in a franchise.
List<LibraryRow> foldFranchises(List<LibraryEntry> entries) {
  final groups = <Object, List<LibraryEntry>>{};
  for (final entry in entries) {
    final key = entry.franchiseId == null
        ? entry.entryId
        : 'franchise ${entry.franchiseId}';
    groups.putIfAbsent(key, () => []).add(entry);
  }
  return [for (final group in groups.values) _foldGroup(group)];
}

LibraryRow _foldGroup(List<LibraryEntry> group) {
  final story = group.where((entry) => !entry.isExtra).toList();
  final current = _currentSeason(story.isEmpty ? group : story);
  final seasonsDone = story.where((e) => e.status == 'completed').length;
  return LibraryRow(
    current: current,
    entryIds: [for (final entry in group) entry.entryId],
    addedAt: group.map((e) => e.addedAt).reduce((a, b) => a > b ? a : b),
    changedAt: group.map((e) => e.changedAt).reduce((a, b) => a > b ? a : b),
    seasonsDone: story.length > 1 ? seasonsDone : null,
    seasonsTotal: story.length > 1 ? story.length : null,
  );
}

/// The earliest season being watched, else the earliest planned, else the
/// earliest on hold, else the latest of the rest. Dropped and not interested
/// seasons count as finished.
LibraryEntry _currentSeason(List<LibraryEntry> seasons) {
  final byRelease = [...seasons]..sort(_byRelease);
  for (final match in [
    (LibraryEntry e) => _watchingStatuses.contains(e.status),
    (LibraryEntry e) => e.status == 'plan_to_watch',
    (LibraryEntry e) => e.status == 'on_hold',
  ]) {
    for (final season in byRelease) {
      if (match(season)) return season;
    }
  }
  return byRelease.last;
}

/// Earliest release first, undated last, then the older entry.
int _byRelease(LibraryEntry a, LibraryEntry b) {
  final aDate = a.startDate;
  final bDate = b.startDate;
  if (aDate != bDate) {
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    final byDate = aDate.compareTo(bDate);
    if (byDate != 0) return byDate;
  }
  final byAdded = a.addedAt.compareTo(b.addedAt);
  return byAdded != 0 ? byAdded : a.entryId.compareTo(b.entryId);
}
