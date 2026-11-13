import 'package:flutter/foundation.dart' show VoidCallback;

import '../data/databases.dart';
import '../data/record_database.dart' show Entry;
import '../library/earlier_titles.dart';
import '../library/entry_edits.dart';
import '../library/entry_status.dart';
import '../library/load_library.dart';
import 'find_earlier_titles.dart';
import 'toast_host.dart';
import 'toast_words.dart';

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

  Future<EditResult> uncheck(String entryId) =>
      _run(entryId, () => edits.uncheck(entryId));

  Future<EditResult> rewatch(String entryId) =>
      _run(entryId, () => edits.rewatch(entryId));

  Future<void> remove(List<String> entryIds) async {
    await edits.remove(entryIds);
    onEdited?.call();
    show(ToastMessage(removed(entryIds.length)));
  }

  Future<void> acceptReview(
    ReviewOffer offer,
    List<EarlierTitle> chosen, {
    EntryStatus status = EntryStatus.completed,
  }) async {
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
  }

  Future<void> notNow(ReviewOffer offer) async {
    final saved = await edits.saveEarlierUnmarked(offer.entryId, offer.titles);
    answerReview(
      ToastMessage(
        reviewSavedForLater,
        undo: _backToReview(offer, saved.run),
        rateEntryId: offer.entryId,
      ),
    );
  }

  Undo _backToReview(ReviewOffer offer, Undo takeBack) => () async {
    await takeBack();
    onEdited?.call();
    show(_reviewToast(offer, rating: await _score(offer.entryId)));
  };

  ToastMessage _reviewToast(ReviewOffer offer, {int? rating}) {
    final undoFinish = offer.undoFinish;
    return ToastMessage(
      reviewOffered(offer.titles.length),
      undo: undoFinish == null ? null : _undoable(undoFinish),
      review: offer,
      rateEntryId: offer.entryId,
      rating: rating,
      onMissed: () => edits.saveEarlierUnmarked(offer.entryId, offer.titles),
    );
  }

  Future<int?> _score(String entryId) async => (await _entry(entryId))?.score;

  Future<Entry?> _entry(String entryId) => (databases.record.select(
    databases.record.entry,
  )..where((row) => row.entryId.equals(entryId))).getSingleOrNull();

  Future<void> rate(String entryId, int? score) async {
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
  ) => was.status == now.status
      ? episodeAdded(now.episodes)
      : markedAs(now.status);

  Undo _undoable(Undo run) => () async {
    await run();
    onEdited?.call();
  };
}
