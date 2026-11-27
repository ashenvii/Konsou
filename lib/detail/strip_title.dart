import '../library/entry_status.dart';
import '../library/row_labels.dart';

/// A title as a strip card on Detail shows it: what is saved of it and the
/// user's entry on it.
class StripTitle {
  const StripTitle({
    required this.malId,
    required this.name,
    this.isLoadingDetails = false,
    this.isScorePending = false,
    this.isNotAired = false,
    this.mediaType,
    this.startDate,
    this.episodes,
    this.malScore,
    this.airedEpisodes,
    this.entryId,
    this.status,
    this.episodesWatched = 0,
  });

  final int malId;
  final String name;

  /// No details saved yet, so they are fetched while it shows.
  final bool isLoadingDetails;

  /// Details saved, but MAL's score not asked for yet.
  final bool isScorePending;
  final bool isNotAired;
  final String? mediaType;
  final String? startDate;
  final int? episodes;
  final double? malScore;

  /// Out so far, for a series on the air.
  final int? airedEpisodes;

  /// Set for a title on the list.
  final String? entryId;
  final EntryStatus? status;
  final int episodesWatched;

  /// The cells in its card's footer.
  CardCount get count => countCard(
    onList: entryId != null,
    watched: episodesWatched,
    total: episodes,
    aired: airedEpisodes,
  );
}
