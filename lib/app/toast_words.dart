import '../library/entry_edits.dart';
import '../library/entry_status.dart';

/// Every word the toasts say, in one place. Change the wording here and
/// nothing else needs to move.

/// After a status change: "Marked as Completed".
String markedAs(EntryStatus status) => 'Marked as ${status.label}';

/// After an episode is added: "Episode 4".
String episodeAdded(int number) => 'Episode $number';

/// Why an edit did nothing (or, for an episode on an airing show, only
/// part of it). Null when there is nothing to say.
String? refusal(EditResult result) => switch (result) {
  EditResult.done => null,
  EditResult.notAiredYet => 'It has not aired yet.',
  EditResult.stillAiring =>
    'It is still airing, so it cannot be marked Completed yet.',
  EditResult.notWatching => 'Only a title set to Watching can get an episode.',
  EditResult.notCompleted => 'Only a Completed title can be rewatched.',
};

/// "1 earlier title" or "3 earlier titles".
String earlierCount(int n) => n == 1 ? '1 earlier title' : '$n earlier titles';

/// The review toast's message, after a finish with earlier titles unmarked:
/// "Frieren S2 completed. 2 earlier titles are not marked."
String reviewOffered(String name, int n) =>
    '$name completed. ${earlierCount(n)} ${n == 1 ? 'is' : 'are'} not marked.';

/// Shown when the finished title has no saved name yet.
const unnamedTitle = 'This title';

/// After "Mark N completed" in the review.
String reviewMarked(int n) => 'Marked ${earlierCount(n)} completed';

/// After auto-mark marked earlier titles on its own.
String autoMarked(int n) => 'Also marked ${earlierCount(n)}';

/// After "Not now" in the review.
const reviewSavedForLater = 'Saved for later. It will be in the bell.';

/// The toast's own buttons.
const undoLabel = 'Undo';
const reviewLabel = 'Review';
const closeToastLabel = 'Close';

/// After a rating from the review toast: "Rated 8".
String rated(int score) => 'Rated $score';

/// What a screen reader says for one of the ten stars.
String rateStarLabel(int score) => 'Rate $score';

/// The review popover.
const extrasHeading = 'Extras';
const notNowLabel = 'Not now';
String markButton(int n) => 'Mark $n completed';
