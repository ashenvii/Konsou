/// One entry as the Library reads it, before franchises are folded.
class LibraryEntry {
  const LibraryEntry({
    required this.entryId,
    required this.name,
    required this.status,
    required this.episodesWatched,
    required this.addedAt,
    required this.changedAt,
    this.score,
    this.malId,
    this.hasDetails = false,
    this.episodes,
    this.mediaType,
    this.startDate,
    this.franchiseId,
    this.isExtra = false,
  });

  final String entryId;

  /// The title in the user's language, else the saved name, else empty.
  final String name;
  final String status;
  final int episodesWatched;
  final int addedAt;
  final int changedAt;
  final int? score;
  final int? malId;
  final bool hasDetails;
  final int? episodes;
  final String? mediaType;

  /// As MAL gives it: a full date, or only a year or a month.
  final String? startDate;

  /// The MAL id of the franchise's title, or null when the scan has not placed
  /// the entry yet.
  final int? franchiseId;
  final bool isExtra;

  @override
  bool operator ==(Object other) =>
      other is LibraryEntry &&
      other.entryId == entryId &&
      other.name == name &&
      other.status == status &&
      other.episodesWatched == episodesWatched &&
      other.addedAt == addedAt &&
      other.changedAt == changedAt &&
      other.score == score &&
      other.malId == malId &&
      other.hasDetails == hasDetails &&
      other.episodes == episodes &&
      other.mediaType == mediaType &&
      other.startDate == startDate &&
      other.franchiseId == franchiseId &&
      other.isExtra == isExtra;

  @override
  int get hashCode => Object.hash(
    entryId,
    name,
    status,
    episodesWatched,
    addedAt,
    changedAt,
    score,
    malId,
    hasDetails,
    episodes,
    mediaType,
    startDate,
    franchiseId,
    isExtra,
  );
}

/// One row of the Library: an entry, or a franchise standing for the season
/// the user is on.
class LibraryRow {
  const LibraryRow({
    required this.current,
    required this.entryIds,
    required this.addedAt,
    required this.changedAt,
    this.seasonsDone,
    this.seasonsTotal,
  });

  final LibraryEntry current;

  final List<String> entryIds;

  /// The newest add and the newest change among those entries.
  final int addedAt;
  final int changedAt;

  /// Seasons finished and seasons on the list, only for a franchise with more
  /// than one season on the list.
  final int? seasonsDone;
  final int? seasonsTotal;

  String get entryId => current.entryId;
  String get name => current.name;
  String get status => current.status;
  int get episodesWatched => current.episodesWatched;
  int? get score => current.score;
  int? get malId => current.malId;
  int? get episodes => current.episodes;
  String? get mediaType => current.mediaType;
  String? get startDate => current.startDate;

  /// No MAL page: Konsou has not found one yet.
  bool get isNotLinked => current.malId == null;

  /// A MAL page, but its details have not come in yet.
  bool get isLoadingDetails => current.malId != null && !current.hasDetails;

  bool get isFranchise => seasonsTotal != null;

  @override
  bool operator ==(Object other) =>
      other is LibraryRow &&
      other.current == current &&
      _sameItems(other.entryIds, entryIds) &&
      other.addedAt == addedAt &&
      other.changedAt == changedAt &&
      other.seasonsDone == seasonsDone &&
      other.seasonsTotal == seasonsTotal;

  @override
  int get hashCode => Object.hash(
    current,
    Object.hashAll(entryIds),
    addedAt,
    changedAt,
    seasonsDone,
    seasonsTotal,
  );
}

/// The rows as the screen holds them. Two snapshots with the same rows are
/// equal, so a reload that found nothing new does not rebuild the screen.
class RowsSnapshot {
  const RowsSnapshot(this.rows);

  final List<LibraryRow>? rows;

  @override
  bool operator ==(Object other) =>
      other is RowsSnapshot && _sameItems(other.rows, rows);

  @override
  int get hashCode => Object.hashAll(rows ?? const []);
}

bool _sameItems<T>(List<T>? first, List<T>? second) {
  if (identical(first, second)) return true;
  if (first == null || second == null || first.length != second.length) {
    return false;
  }
  for (var i = 0; i < first.length; i++) {
    if (first[i] != second[i]) return false;
  }
  return true;
}
