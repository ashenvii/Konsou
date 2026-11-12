class EarlierTitle {
  const EarlierTitle({
    required this.malId,
    required this.name,
    required this.isExtra,
    this.entryId,
    this.mediaType,
    this.startDate,
    this.episodes,
    this.status,
  });

  final int malId;
  final String? entryId;
  final String name;
  final bool isExtra;
  final String? mediaType;
  final String? startDate;
  final int? episodes;

  /// What it is on the list as, in the record's own words, or null when it
  /// is not on the list at all.
  final String? status;
}
