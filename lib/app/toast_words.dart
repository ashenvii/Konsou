import '../library/entry_edits.dart';
import '../library/entry_status.dart';

/// Toast text after +1.
String episodeAdded(int number) => 'Episode $number';

/// Why an edit was refused, or null when it went through.
String? refusal(EditResult result) => switch (result) {
  EditResult.done => null,
  EditResult.notAiredYet => 'Not aired yet.',
  EditResult.stillAiring => 'Still airing.',
  EditResult.notWatching => 'Set it to Watching first.',
  EditResult.notCompleted => 'Not completed yet.',
};

/// Toast text when a finish leaves earlier titles unmarked.
String reviewOffered(int count) => 'Completed. $count earlier not marked.';

/// The toast after a review's mark. Completed keeps the old wording.
String reviewMarkedAs(int count, EntryStatus status) {
  if (count == 0) return 'Nothing changed';
  if (status == EntryStatus.completed) return 'Marked $count earlier';
  return 'Marked $count as ${status.label.toLowerCase()}';
}

/// Review label in front of the status the titles are set to.
const reviewSetTo = 'Set to';

/// Toast text after adding an entry with a status.
String addedAs(EntryStatus status) => 'Added as ${status.label}';

/// Toast text when earlier titles were marked without asking.
String autoMarked(int count) => 'Also marked $count earlier';

/// Toast text when the review is put off.
const reviewSavedForLater = 'Saved for later.';

/// Toast text after removing one or more entries.
String removed(int count) => count == 1 ? 'Removed' : 'Removed $count';

/// The toast's Undo action.
const undoLabel = 'Undo';
/// The toast's action that opens the earlier titles review.
const reviewLabel = 'Review';
/// The toast's close button.
const closeToastLabel = 'Close';

/// Label of the star that rates [score].
String rateStarLabel(int score) => 'Rate $score';
/// Label of the rating's clear action.
const clearRatingLabel = 'Clear';

/// Heading of the earlier titles review.
const reviewHeading = 'Mark earlier titles as completed';
/// Review heading over titles outside the main story.
const extrasHeading = 'Extras';
/// Review action that puts it off.
const notNowLabel = 'Not now';
/// Review button that marks the chosen titles.
String markButton(int count) => 'Mark $count';

/// Review heading over the story titles in watch order.
const storiesHeading = 'In watch order';
/// Review action that selects every title.
const selectAllLabel = 'All';
/// Review action that clears the selection.
const selectNoneLabel = 'None';
/// Status shown for a title not on the user's list.
const notOnListLabel = 'Not on your list';
/// How many titles the review has selected.
String selectedCount(int count, int total) => '$count of $total selected';
/// A stored status as the review shows it.
String earlierStatusLabel(String? stored) {
  if (stored == null) return notOnListLabel;
  try {
    return EntryStatus.parse(stored).label;
  } on StateError {
    return stored;
  }
}
