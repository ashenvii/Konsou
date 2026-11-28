import 'package:flutter/foundation.dart' show VoidCallback;

import '../data/databases.dart';
import '../data/record_database.dart' show Entry;
import '../detail/title_entry.dart';
import '../library/earlier_titles.dart';
import '../library/entry_edits.dart';
import '../library/entry_status.dart';
import '../library/load_library.dart';
import 'find_earlier_titles.dart';
import 'toast_host.dart';
import 'toast_words.dart';

/// Entry edits as screens call them, with the toast, undo and review after.
class EntryActions {
  EntryActions({
    required this.databases,
    required this.edits,
    required this.show,
    required this.answerReview,
    this.onEdited,
  });

  final Databases databases;
  final EntryEdits edits;
  final ToastSink show;

  final ToastSink answerReview;

  final VoidCallback? onEdited;

  Future<EditResult> setStatus(String entryId, EntryStatus target) =>
      _run(entryId, () => edits.setStatus(entryId, target));

  Future<EditResult> addEpisode(String entryId) =>
      _run(entryId, () => edits.addEpisode(entryId));

  Future<EditResult> setEpisodes(String entryId, int count) =>
      _run(entryId, () => edits.setEpisodes(entryId, count));

  Future<EditResult> uncheck(String entryId) =>
      _run(entryId, () => edits.uncheck(entryId));

  Future<EditResult> rewatch(String entryId) =>
      _run(entryId, () => edits.rewatch(entryId));

  /// Adds a title that is not on the list with the status the user picked.
  /// Completed starts the earlier-titles check, as any finish does.
  Future<void> add(
    EarlierTitle title,
    EntryStatus status, {
    String? airing,
  }) => _inTurn(() async {
    if (_refusedOnAdd(status, airing)) return;
    final mark = await edits.markEarlier(
      [title],
      status: status,
      withName: true,
    );
    onEdited?.call();
    final added = await readEntryOnPage(databases, title.malId);
    if (added == null) return;
    if (added.status == EntryStatus.completed &&
        await _offerEarlier(added.entryId, mark.undo)) {
      return;
    }
    // a lock the caller could not see leaves it Planned, and the toast says so
    show(ToastMessage(addedAs(added.status), undo: _undoable(mark.undo.run)));
  });

  /// Sets [status] on the title's entry, or adds the title with it when it is
  /// not on the list.
  Future<void> setOrAdd(
    EarlierTitle title,
    EntryStatus status, {
    String? airing,
  }) async {
    final entryId = title.entryId;
    entryId != null
        ? await setStatus(entryId, status)
        : await add(title, status, airing: airing);
  }

  // notes and dates change nothing the Library shows, so it is not told
  Future<void> setNotes(String entryId, String text) =>
      _inTurn(() => edits.setNotes(entryId, text));

  Future<void> setStartedDate(String entryId, DateTime? date) =>
      _inTurn(() => edits.setStartedDate(entryId, date));

  // the locks the status menu has, for a title with no entry to ask yet
  bool _refusedOnAdd(EntryStatus status, String? airing) {
    final locked = findAiringLock(airing, status);
    if (locked != null) _explainRefusal(locked);
    return locked != null;
  }

  Future<void> remove(List<String> entryIds) => _inTurn(() async {
    await edits.remove(entryIds);
    onEdited?.call();
    show(ToastMessage(removed(entryIds.length)));
  });

  Future<void> acceptReview(
    ReviewOffer offer,
    List<EarlierTitle> chosen, {
    EntryStatus status = EntryStatus.completed,
  }) => _inTurn(() async {
    if (chosen.isEmpty) return;
    final mark = await edits.markEarlier(chosen, status: status);
    onEdited?.call();
    answerReview(
      ToastMessage(
        reviewMarkedAs(mark.applied, status),
        undo: _backToReview(offer, mark.undo.run),
        rateEntryId: offer.entryId,
      ),
    );
  });

  Future<void> notNow(ReviewOffer offer) => _inTurn(() async {
    final saved = await edits.saveEarlierUnmarked(offer.entryId, offer.titles);
    answerReview(
      ToastMessage(
        reviewSavedForLater,
        undo: _backToReview(offer, saved.run),
        rateEntryId: offer.entryId,
      ),
    );
  });

  Undo _backToReview(ReviewOffer offer, Undo takeBack) =>
      () => _inTurn(() async {
        await takeBack();
        onEdited?.call();
        show(_reviewToast(offer, rating: await _score(offer.entryId)));
      });

  ToastMessage _reviewToast(ReviewOffer offer, {int? rating}) {
    final undoFinish = offer.undoFinish;
    return ToastMessage(
      reviewOffered(offer.titles.length),
      undo: undoFinish == null ? null : _undoable(undoFinish),
      review: offer,
      rateEntryId: offer.entryId,
      rating: rating,
      onMissed: () =>
          _inTurn(() => edits.saveEarlierUnmarked(offer.entryId, offer.titles)),
    );
  }

  Future<int?> _score(String entryId) async => (await _entry(entryId))?.score;

  Future<Entry?> _entry(String entryId) => (databases.record.select(
    databases.record.entry,
  )..where((row) => row.entryId.equals(entryId))).getSingleOrNull();

  Future<void> rate(String entryId, int? score) => _inTurn(() async {
    await edits.setScore(entryId, score);
    onEdited?.call();
  });

  // one edit at a time, so two quick presses never read the same old count
  var _turn = Future<void>.value();

  Future<T> _inTurn<T>(Future<T> Function() action) {
    final result = _turn.then((_) => action());
    _turn = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<EditResult> _run(String entryId, Future<EditResult> Function() edit) =>
      _inTurn(() => _runNow(entryId, edit));

  Future<EditResult> _runNow(
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
      _explainRefusal(result);
      return result;
    }
    final finished =
        now.status == EntryStatus.completed &&
        was.status != EntryStatus.completed;
    if (finished && await _offerEarlier(entryId, before)) return result;
    if (result != EditResult.done) {
      // the episode went in but the show could not be finished
      _explainRefusal(result);
      return result;
    }
    show(ToastMessage(_describe(was, now), undo: _undoable(before.run)));
    return result;
  }

  void _explainRefusal(EditResult result) {
    final reason = refusal(result);
    if (reason != null) show(ToastMessage(reason));
  }

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
            await marked.undo.run();
            await finish.run();
          }),
        ),
      );
      return true;
    }
    show(
      _reviewToast(
        ReviewOffer(entryId: entryId, titles: titles, undoFinish: finish.run),
      ),
    );
    return true;
  }

  Future<({EntryStatus status, int episodes})> _progress(String entryId) async {
    final entry = (await _entry(entryId))!;
    return (
      status: EntryStatus.parse(entry.status),
      episodes: entry.episodesWatched,
    );
  }

  String _describe(
    ({EntryStatus status, int episodes}) was,
    ({EntryStatus status, int episodes}) now,
  ) => was.status == now.status ? episodeAdded(now.episodes) : now.status.label;

  Undo _undoable(Undo run) =>
      () => _inTurn(() async {
        await run();
        onEdited?.call();
      });
}
