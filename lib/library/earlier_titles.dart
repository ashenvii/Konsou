/// A title released before one the user just finished, in the same franchise
/// and not marked Completed. [entryId] is null when it is not on the list.
class EarlierTitle {
  const EarlierTitle({
    required this.malId,
    required this.name,
    required this.isExtra,
    this.entryId,
    this.mediaType,
    this.startDate,
    this.episodes,
  });

  final int malId;
  final String? entryId;
  final String name;
  final bool isExtra;
  final String? mediaType;
  final String? startDate;
  final int? episodes;
}
