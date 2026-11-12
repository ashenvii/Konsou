import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../library/earlier_titles.dart';
import '../library/entry_edits.dart';
import '../library/entry_status.dart';
import '../library/load_library.dart';
import '../library/title_language.dart';
import 'find_earlier_titles.dart';
import 'toast_host.dart';
import 'toast_words.dart';

/// What the screens call to change an entry. It runs the edit, tells the user
/// what came of it with a toast (an Undo for a change, the reason for a
/// refusal), and after a title is finished checks for earlier ones to mark.
class EntryActions {
  EntryActions({
    required this.databases,
    required this.edits,
    required this.show,
    required this.dismiss,
    this.onEdited,
  });

  final Databases databases;
  final EntryEdits edits;
  final void Function(ToastMessage message) show;
  final void Function() dismiss;

  /// Runs after any change this class makes, an Undo included, so a screen
  /// showing the entries can reload.
  final void Function()? onEdited;

  Future<EditResult> setStatus(String entryId, EntryStatus target) =>
      _run(entryId, () => edits.setStatus(entryId, target));

  Future<EditResult> addEpisode(String entryId) =>
      _run(entryId, () => edits.addEpisode(entryId));

  Future<EditResult> uncheck(String entryId) =>
      _run(entryId, () => edits.uncheck(entryId));

  Future<EditResult> rewatch(String entryId) =>
      _run(entryId, () => edits.rewatch(entryId));

  /// Removes entries for good. No toast and no Undo: holding the button was
  /// the confirmation.
  Future<void> remove(List<String> entryIds) => edits.remove(entryIds);

  /// Marks the ticked earlier titles from the review.
  Future<void> acceptReview(List<EarlierTitle> titles) async {
    dismiss();
    if (titles.isEmpty) return;
    final undo = await edits.markEarlier(titles);
    onEdited?.call();
    show(ToastMessage(reviewMarked(titles.length), undo: _undoable(undo.run)));
  }

  /// "Not now": keeps a reminder for the bell.
  Future<void> notNow(ReviewOffer offer) async {
    dismiss();
    await edits.saveEarlierUnmarked(offer.entryId, offer.titles);
    show(ToastMessage(reviewSavedForLater));
  }

  /// A rating from the review toast.
  Future<void> rate(String entryId, int score) async {
    await edits.setScore(entryId, score);
    onEdited?.call();
  }

  Future<EditResult> _run(
    String entryId,
    Future<EditResult> Function() edit,
  ) async {
    final before = await edits.snapshot([entryId]);
    final was = await _progress(entryId);
    final result = await edit();
    final now = await _progress(entryId);
    onEdited?.call();
    final changed = was.status != now.status || was.episodes != now.episodes;
    if (!changed) {
      final reason = refusal(result);
      if (reason != null) show(ToastMessage(reason));
      return result;
    }
    final finished =
        now.status == EntryStatus.completed &&
        was.status != EntryStatus.completed;
    if (finished && await _offerEarlier(entryId, before)) return result;
    if (result != EditResult.done) {
      // the episode went in but the show could not be finished
      final reason = refusal(result);
      if (reason != null) show(ToastMessage(reason));
      return result;
    }
    show(ToastMessage(_describe(was, now), undo: _undoable(before.run)));
    return result;
  }

  /// After a finish: auto-marks earlier titles or shows the review toast.
  /// True when it showed a toast of its own.
  Future<bool> _offerEarlier(String entryId, UndoEdit finish) async {
    final language = await readTitleLanguage(databases.record);
    final titles = await findEarlierTitles(databases, entryId, language);
    if (titles.isEmpty) return false;
    if (await edits.readAutoMarkEarlier()) {
      final marked = await edits.markEarlier(titles);
      onEdited?.call();
      show(
        ToastMessage(
          autoMarked(titles.length),
          undo: _undoable(() async {
            await marked.run();
            await finish.run();
          }),
        ),
      );
      return true;
    }
    final name = await _nameOf(entryId, language);
    show(
      ToastMessage(
        reviewOffered(name, titles.length),
        undo: _undoable(finish.run),
        review: ReviewOffer(entryId: entryId, titles: titles),
      ),
    );
    return true;
  }

  Future<String> _nameOf(String entryId, TitleLanguage language) async {
    final rows = await databases.record
        .customSelect(
          '''
          SELECT detail.title, detail.title_english, detail.title_japanese,
            NULL AS name
          FROM entry_reference reference
          JOIN details.detail detail ON detail.provider = 'mal'
            AND detail.provider_id = reference.provider_id
          WHERE reference.entry_id = ? AND reference.provider = 'mal'
          ''',
          variables: [Variable.withString(entryId)],
        )
        .get();
    if (rows.isEmpty) return unnamedTitle;
    final name = pickTitleName(rows.first, language);
    return name.isEmpty ? unnamedTitle : name;
  }

  Future<({EntryStatus status, int episodes})> _progress(String entryId) async {
    final entry = await (databases.record.select(
      databases.record.entry,
    )..where((row) => row.entryId.equals(entryId))).getSingle();
    return (
      status: EntryStatus.parse(entry.status),
      episodes: entry.episodesWatched,
    );
  }

  String _describe(
    ({EntryStatus status, int episodes}) was,
    ({EntryStatus status, int episodes}) now,
  ) => was.status == now.status
      ? episodeAdded(now.episodes)
      : markedAs(now.status);

  Future<void> Function() _undoable(Future<void> Function() run) => () async {
    await run();
    onEdited?.call();
  };
}
