import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../data/edit_clock.dart';
import '../data/record_database.dart';
import 'entry_status.dart';

/// What came of an edit. Anything but [done] changed nothing, or for an
/// episode on an airing show only the episode, and says why.
enum EditResult { done, notAiredYet, stillAiring, notWatching, notCompleted }

/// What the user does to entries from the Library: change the status, add an
/// episode, finish, take a finish back, rewatch, remove. Every change is timed
/// by the edit clock and [onChanged] runs once it is saved, so sync can follow.
class EntryEdits {
  EntryEdits({
    required this.databases,
    this.onChanged,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Databases databases;
  final void Function()? onChanged;
  final DateTime Function() _now;

  RecordDatabase get _record => databases.record;

  Future<EditResult> setStatus(String entryId, EntryStatus target) async {
    final facts = await _readFacts(entryId);
    if (facts.status == target) return EditResult.done;
    if (target == EntryStatus.rewatching &&
        facts.status == EntryStatus.completed) {
      return rewatch(entryId);
    }
    final locked = _lockFor(facts, target);
    if (locked != null) return locked;
    await _record.transaction(() async {
      final time = await readEditTime(_record, _now());
      final finishing = target == EntryStatus.completed;
      final episodes = finishing
          ? _maxOf(facts.total, facts.episodesWatched)
          : facts.episodesWatched;
      await _writeProgress(entryId, time, status: target, episodes: episodes);
      if (finishing) {
        await _logCompletion(entryId, facts, episodes);
      } else if (facts.status == EntryStatus.completed) {
        await _takeBackLastCompletion(entryId);
      }
    });
    onChanged?.call();
    return EditResult.done;
  }

  /// One more episode for a title being watched. The last one finishes the
  /// show, unless it is still airing: then the episode is added and the show
  /// stays as it is.
  Future<EditResult> addEpisode(String entryId) async {
    final facts = await _readFacts(entryId);
    if (!watchingStatuses.contains(facts.status.value)) {
      return EditResult.notWatching;
    }
    final total = facts.total;
    if (total != null && facts.episodesWatched >= total) return EditResult.done;
    final episodes = facts.episodesWatched + 1;
    final finishes = total != null && episodes >= total;
    final locked = finishes ? _lockFor(facts, EntryStatus.completed) : null;
    await _record.transaction(() async {
      final time = await readEditTime(_record, _now());
      if (finishes && locked == null) {
        await _writeProgress(
          entryId,
          time,
          status: EntryStatus.completed,
          episodes: episodes,
        );
        await _logCompletion(entryId, facts, episodes);
      } else {
        await _writeProgress(
          entryId,
          time,
          status: facts.status,
          episodes: episodes,
        );
      }
    });
    onChanged?.call();
    return locked ?? EditResult.done;
  }

  /// The Library checkbox turned off: Watching if any episode was watched,
  /// else Planned. The finished watch it logged is taken back.
  Future<EditResult> uncheck(String entryId) async {
    final facts = await _readFacts(entryId);
    if (facts.status != EntryStatus.completed) return EditResult.done;
    return setStatus(
      entryId,
      facts.episodesWatched > 0 ? EntryStatus.watching : EntryStatus.planned,
    );
  }

  /// A finished title starts again from zero. The finished watch stays; the
  /// next finish logs the next one.
  Future<EditResult> rewatch(String entryId) async {
    final facts = await _readFacts(entryId);
    if (facts.status != EntryStatus.completed) return EditResult.notCompleted;
    await _record.transaction(() async {
      final time = await readEditTime(_record, _now());
      await _writeProgress(
        entryId,
        time,
        status: EntryStatus.rewatching,
        episodes: 0,
      );
    });
    onChanged?.call();
    return EditResult.done;
  }

  /// Deletes the entries and everything tied to them. Only the removal mark
  /// stays, so sync can tell the other devices. Covers fall into the pool.
  Future<void> remove(List<String> entryIds) async {
    if (entryIds.isEmpty) return;
    await _record.transaction(() async {
      final time = await readEditTime(_record, _now());
      for (final id in entryIds) {
        final withId = [Variable.withString(id)];
        for (final table in [
          'completion',
          'alert',
          'details.match_suggestion',
          'details.match_attempt',
          'details.franchise_link',
        ]) {
          await _record.customUpdate(
            'DELETE FROM $table WHERE entry_id = ?',
            variables: withId,
            updates: {},
          );
        }
        // references and declines go with the entry
        await (_record.delete(
          _record.entry,
        )..where((row) => row.entryId.equals(id))).go();
        await _record
            .into(_record.deletion)
            .insertOnConflictUpdate(
              DeletionCompanion.insert(entryId: id, deletedAt: time),
            );
      }
    });
    onChanged?.call();
  }

  EditResult? _lockFor(_Facts facts, EntryStatus target) {
    if (facts.airing == 'not_yet_aired' &&
        {
          EntryStatus.watching,
          EntryStatus.rewatching,
          EntryStatus.completed,
        }.contains(target)) {
      return EditResult.notAiredYet;
    }
    if (facts.airing == 'currently_airing' && target == EntryStatus.completed) {
      return EditResult.stillAiring;
    }
    return null;
  }

  Future<void> _writeProgress(
    String entryId,
    int time, {
    required EntryStatus status,
    required int episodes,
  }) =>
      (_record.update(
        _record.entry,
      )..where((row) => row.entryId.equals(entryId))).write(
        EntryCompanion(
          status: Value(status.value),
          episodesWatched: Value(episodes),
          progressChangedAt: Value(time),
        ),
      );

  Future<void> _logCompletion(
    String entryId,
    _Facts facts,
    int episodes,
  ) async {
    final latest = await _lastWatchNumber(entryId);
    final seconds = facts.secondsPerEpisode;
    await _record
        .into(_record.completion)
        .insert(
          CompletionCompanion.insert(
            entryId: entryId,
            watchNumber: latest == null ? 0 : latest + 1,
            completedAt: _now().millisecondsSinceEpoch,
            episodesWatched: Value(episodes),
            minutesPerEpisode: Value(
              seconds == null || seconds <= 0 ? null : (seconds / 60).round(),
            ),
          ),
        );
  }

  Future<void> _takeBackLastCompletion(String entryId) async {
    final latest = await _lastWatchNumber(entryId);
    if (latest == null) return;
    await (_record.delete(_record.completion)..where(
          (row) => row.entryId.equals(entryId) & row.watchNumber.equals(latest),
        ))
        .go();
  }

  Future<int?> _lastWatchNumber(String entryId) async {
    final rows = await _record
        .customSelect(
          'SELECT MAX(watch_number) AS latest FROM completion WHERE entry_id = ?',
          variables: [Variable.withString(entryId)],
        )
        .get();
    return rows.single.read<int?>('latest');
  }

  Future<_Facts> _readFacts(String entryId) async {
    final rows = await _record
        .customSelect(
          '''
          SELECT entry.status, entry.episodes_watched,
            detail.airing_status, detail.episodes,
            json_extract(detail.json, '\$.average_episode_duration') AS seconds
          FROM entry
          LEFT JOIN entry_reference reference
            ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
          LEFT JOIN details.detail detail
            ON detail.provider = 'mal'
            AND detail.provider_id = reference.provider_id
          WHERE entry.entry_id = ?
          ''',
          variables: [Variable.withString(entryId)],
        )
        .get();
    final row = rows.single;
    return _Facts(
      status: EntryStatus.parse(row.read<String>('status')),
      episodesWatched: row.read<int>('episodes_watched'),
      airing: row.read<String?>('airing_status'),
      total: row.read<int?>('episodes'),
      secondsPerEpisode: row.read<int?>('seconds'),
    );
  }

  int _maxOf(int? total, int watched) =>
      total == null || total < watched ? watched : total;
}

class _Facts {
  const _Facts({
    required this.status,
    required this.episodesWatched,
    this.airing,
    this.total,
    this.secondsPerEpisode,
  });

  final EntryStatus status;
  final int episodesWatched;
  final String? airing;
  final int? total;
  final int? secondsPerEpisode;
}
