import 'dart:math';

import 'entry_status.dart';
import 'library_row.dart';

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
  final seasonsDone = story
      .where((entry) => entry.status == 'completed')
      .length;
  return LibraryRow(
    current: current,
    entryIds: [for (final entry in group) entry.entryId],
    addedAt: group.map((entry) => entry.addedAt).reduce(max),
    changedAt: group.map((entry) => entry.changedAt).reduce(max),
    seasonsDone: story.length > 1 ? seasonsDone : null,
    seasonsTotal: story.length > 1 ? story.length : null,
  );
}

/// The earliest season being watched, else the earliest planned, else the
/// earliest on hold, else the latest dated one of the rest. Dropped and not
/// interested seasons are among the rest here; the season count still counts
/// only completed ones.
LibraryEntry _currentSeason(List<LibraryEntry> seasons) {
  final byRelease = [...seasons]..sort(_byRelease);
  for (final isCurrent in [
    (LibraryEntry entry) => watchingStatuses.contains(entry.status),
    (LibraryEntry entry) => entry.status == 'plan_to_watch',
    (LibraryEntry entry) => entry.status == 'on_hold',
  ]) {
    for (final season in byRelease) {
      if (isCurrent(season)) return season;
    }
  }
  // an undated season is never the latest while a dated one exists
  final dated = byRelease.where((season) => season.startDate != null);
  return dated.isEmpty ? byRelease.last : dated.last;
}

/// Earliest release first, undated last, then the older entry.
int _byRelease(LibraryEntry first, LibraryEntry second) {
  final firstDate = first.startDate;
  final secondDate = second.startDate;
  if (firstDate != secondDate) {
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;
    final byDate = firstDate.compareTo(secondDate);
    if (byDate != 0) return byDate;
  }
  final byAdded = first.addedAt.compareTo(second.addedAt);
  return byAdded != 0 ? byAdded : first.entryId.compareTo(second.entryId);
}
