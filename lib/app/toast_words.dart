import '../library/entry_edits.dart';
import '../library/entry_status.dart';

String markedAs(EntryStatus status) => status.label;

String episodeAdded(int number) => 'Episode $number';

String? refusal(EditResult result) => switch (result) {
  EditResult.done => null,
  EditResult.notAiredYet => 'Not aired yet.',
  EditResult.stillAiring => 'Still airing.',
  EditResult.notWatching => 'Set it to Watching first.',
  EditResult.notCompleted => 'Not completed yet.',
};

String reviewOffered(int n) => 'Completed. $n earlier not marked.';

/// The toast after a review's mark. Completed keeps the old wording.
String reviewMarkedAs(int n, EntryStatus status) {
  if (n == 0) return 'Nothing changed';
  if (status == EntryStatus.completed) return 'Marked $n earlier';
  return 'Marked $n as ${status.label.toLowerCase()}';
}

const reviewSetTo = 'Set to';

String autoMarked(int n) => 'Also marked $n earlier';

const reviewSavedForLater = 'Saved for later.';

String removed(int n) => n == 1 ? 'Removed' : 'Removed $n';

const undoLabel = 'Undo';
const reviewLabel = 'Review';
const closeToastLabel = 'Close';

String rateStarLabel(int score) => 'Rate $score';
const clearRatingLabel = 'Clear';

const reviewHeading = 'Mark earlier titles as completed';
const extrasHeading = 'Extras';
const notNowLabel = 'Not now';
String markButton(int n) => 'Mark $n';

const storiesHeading = 'In watch order';
const selectAllLabel = 'All';
const selectNoneLabel = 'None';
const notOnListLabel = 'Not on your list';
String selectedCount(int n, int total) => '$n of $total selected';
String episodeCount(int n) => n == 1 ? '1 episode' : '$n episodes';

String mediaTypeLabel(String type) => switch (type) {
  'tv' => 'TV',
  'movie' => 'Movie',
  'ova' => 'OVA',
  'ona' => 'ONA',
  'special' => 'Special',
  'tv_special' => 'TV special',
  'music' => 'Music',
  'cm' => 'Commercial',
  'pv' => 'Promo',
  _ => type.toUpperCase(),
};

String earlierStatusLabel(String? stored) {
  if (stored == null) return notOnListLabel;
  try {
    return EntryStatus.parse(stored).label;
  } on StateError {
    return stored;
  }
}
