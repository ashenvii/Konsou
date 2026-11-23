import '../library/entry_edits.dart';
import '../library/entry_status.dart';

String episodeAdded(int number) => 'Episode $number';

String? refusal(EditResult result) => switch (result) {
  EditResult.done => null,
  EditResult.notAiredYet => 'Not aired yet.',
  EditResult.stillAiring => 'Still airing.',
  EditResult.notWatching => 'Set it to Watching first.',
  EditResult.notCompleted => 'Not completed yet.',
};

String reviewOffered(int count) => 'Completed. $count earlier not marked.';

/// The toast after a review's mark. Completed keeps the old wording.
String reviewMarkedAs(int count, EntryStatus status) {
  if (count == 0) return 'Nothing changed';
  if (status == EntryStatus.completed) return 'Marked $count earlier';
  return 'Marked $count as ${status.label.toLowerCase()}';
}

const reviewSetTo = 'Set to';

String addedAs(EntryStatus status) => 'Added as ${status.label}';

String autoMarked(int count) => 'Also marked $count earlier';

const reviewSavedForLater = 'Saved for later.';

String removed(int count) => count == 1 ? 'Removed' : 'Removed $count';

const undoLabel = 'Undo';
const reviewLabel = 'Review';
const closeToastLabel = 'Close';

String rateStarLabel(int score) => 'Rate $score';
const clearRatingLabel = 'Clear';

const reviewHeading = 'Mark earlier titles as completed';
const extrasHeading = 'Extras';
const notNowLabel = 'Not now';
String markButton(int count) => 'Mark $count';

const storiesHeading = 'In watch order';
const selectAllLabel = 'All';
const selectNoneLabel = 'None';
const notOnListLabel = 'Not on your list';
String selectedCount(int count, int total) => '$count of $total selected';
String earlierStatusLabel(String? stored) {
  if (stored == null) return notOnListLabel;
  try {
    return EntryStatus.parse(stored).label;
  } on StateError {
    return stored;
  }
}
