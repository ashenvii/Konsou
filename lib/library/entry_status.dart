/// The two statuses that count as watching now.
const watchingStatuses = {'watching', 'rewatching'};

/// What the user is doing with an entry. [value] is what the record stores,
/// MAL's own words, so import and export match.
enum EntryStatus {
  watching('watching'),
  planned('plan_to_watch'),
  completed('completed'),
  onHold('on_hold'),
  dropped('dropped'),
  rewatching('rewatching'),
  notInterested('not_interested');

  const EntryStatus(this.value);

  final String value;

  static EntryStatus parse(String stored) =>
      values.firstWhere((status) => status.value == stored);
}
