/// Which title name to show. Stored as the `title_language` setting.
enum TitleLanguage {
  romaji,
  english,
  japanese;

  /// The stored words are the old app's: romaji, english and native.
  static TitleLanguage parse(String? stored) => switch (stored) {
    'english' => english,
    'native' || 'japanese' => japanese,
    _ => romaji,
  };
}

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

  /// The entry this row stands for.
  final LibraryEntry current;

  /// Every entry the row covers, the one above included.
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
}

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
