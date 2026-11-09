/// The two statuses that count as watching now.
const watchingStatuses = {'watching', 'rewatching'};

/// What the user is doing with an entry. [value] is what the record stores,
/// MAL's own words, so import and export match.
enum EntryStatus {
  watching('watching', 'Watching'),
  planned('plan_to_watch', 'Planned'),
  completed('completed', 'Completed'),
  onHold('on_hold', 'On hold'),
  dropped('dropped', 'Dropped'),
  rewatching('rewatching', 'Rewatching'),
  notInterested('not_interested', 'Not interested');

  const EntryStatus(this.value, this.label);

  final String value;

  /// The word the screens show.
  final String label;

  static EntryStatus parse(String stored) =>
      values.firstWhere((status) => status.value == stored);
}
