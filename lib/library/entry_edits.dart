import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../data/edit_clock.dart';
import '../data/generate_id.dart';
import '../data/record_database.dart';
import 'earlier_titles.dart';
import 'entry_status.dart';

enum EditResult { done, notAiredYet, stillAiring, notWatching, notCompleted }

class UndoEdit {
  const UndoEdit(this.run);

  final Future<void> Function() run;
}

/// What an earlier-titles mark did: how many titles it changed, and the way
/// back.
class EarlierMark {
  const EarlierMark(this.undo, this.applied);

  final UndoEdit undo;
  final int applied;
}

const autoMarkEarlierKey = 'auto_mark_earlier';

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

  Future<EditResult> uncheck(String entryId) async {
    final facts = await _readFacts(entryId);
    if (facts.status != EntryStatus.completed) return EditResult.done;
    return setStatus(
      entryId,
      facts.episodesWatched > 0 ? EntryStatus.watching : EntryStatus.planned,
    );
  }

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

  Future<UndoEdit> snapshot(List<String> entryIds) async {
    final entries = await (_record.select(
      _record.entry,
    )..where((row) => row.entryId.isIn(entryIds))).get();
    final watches = await (_record.select(
      _record.completion,
    )..where((row) => row.entryId.isIn(entryIds))).get();
    return UndoEdit(() => _restore(entries, watches));
  }

  Future<void> _restore(List<Entry> entries, List<Completion> watches) async {
    if (entries.isEmpty) return;
    final ids = {for (final entry in entries) entry.entryId};
    await _record.transaction(() async {
      final time = await readEditTime(_record, _now());
      for (final entry in entries) {
        await (_record.update(
          _record.entry,
        )..where((row) => row.entryId.equals(entry.entryId))).write(
          EntryCompanion(
            status: Value(entry.status),
            episodesWatched: Value(entry.episodesWatched),
            startedAt: Value(entry.startedAt),
            progressChangedAt: Value(time),
          ),
        );
      }
      await (_record.delete(
        _record.completion,
      )..where((row) => row.entryId.isIn(ids))).go();
      for (final watch in watches) {
        await _record.into(_record.completion).insert(watch);
      }
    });
    onChanged?.call();
  }

  Future<void> setScore(String entryId, int? score) async {
    await _record.transaction(() async {
      final time = await readEditTime(_record, _now());
      await (_record.update(
        _record.entry,
      )..where((row) => row.entryId.equals(entryId))).write(
        EntryCompanion(score: Value(score), scoreChangedAt: Value(time)),
      );
    });
    onChanged?.call();
  }

  /// Sets each earlier title to [status]. Completed fills the episode count
  /// and logs an estimated completion; any other status only sets the status
  /// and keeps the episodes. Titles a lock forbids are skipped and not counted.
  ///
  /// [withName] saves each added title's name on its new entry, so a title
  /// added from a search is readable before its details come in.
  Future<EarlierMark> markEarlier(
    List<EarlierTitle> titles, {
    EntryStatus status = EntryStatus.completed,
    bool withName = false,
  }) async {
    final onList = [for (final title in titles) ?title.entryId];
    final restore = await snapshot(onList);
    final created = <String>[];
    var applied = 0;
    await _record.transaction(() async {
      final time = await readEditTime(_record, _now());
      for (final title in titles) {
        var entryId = title.entryId;
        if (entryId == null) {
          entryId = generateId();
          created.add(entryId);
          await _record
              .into(_record.entry)
              .insert(
                EntryCompanion.insert(
                  entryId: entryId,
                  status: EntryStatus.planned.value,
                  addedAt: _now().millisecondsSinceEpoch,
                  progressChangedAt: time,
                  name: withName ? Value(title.name) : const Value.absent(),
                ),
              );
          await _record
              .into(_record.entryReference)
              .insert(
                EntryReferenceCompanion.insert(
                  entryId: entryId,
                  provider: 'mal',
                  providerId: title.malId,
                ),
              );
        }
        final facts = await _readFacts(entryId);
        if (facts.status == status) continue;
        if (_lockFor(facts, status) != null) continue;
        if (status == EntryStatus.completed) {
          final episodes = _maxOf(
            title.episodes ?? facts.total,
            facts.episodesWatched,
          );
          await _writeProgress(
            entryId,
            time,
            status: EntryStatus.completed,
            episodes: episodes,
          );
          await _logCompletion(entryId, facts, episodes, estimated: true);
        } else {
          if (facts.status == EntryStatus.completed) {
            await _takeBackLastCompletion(entryId);
          }
          await _writeProgress(
            entryId,
            time,
            status: status,
            episodes: facts.episodesWatched,
          );
        }
        applied++;
      }
    });
    onChanged?.call();
    return EarlierMark(
      UndoEdit(() async {
        await restore.run();
        await remove(created);
      }),
      applied,
    );
  }

  Future<UndoEdit> saveEarlierUnmarked(
    String entryId,
    List<EarlierTitle> titles,
  ) async {
    // reminders already kept stay if this is undone; only new ones go
    final before = {
      for (final alert
          in await (_record.select(_record.alert)..where(
                (alert) =>
                    alert.entryId.equals(entryId) &
                    alert.type.equals('earlier_unmarked'),
              ))
              .get())
        alert.relatedProviderId,
    };
    final added = [
      for (final title in titles)
        if (!before.contains(title.malId)) title.malId,
    ];
    await _record.transaction(() async {
      for (final title in titles) {
        await _record
            .into(_record.alert)
            .insert(
              AlertCompanion.insert(
                entryId: entryId,
                relatedProvider: 'mal',
                relatedProviderId: title.malId,
                type: 'earlier_unmarked',
                createdAt: _now().millisecondsSinceEpoch,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
    onChanged?.call();
    return UndoEdit(() async {
      await (_record.delete(_record.alert)..where(
            (alert) =>
                alert.entryId.equals(entryId) &
                alert.type.equals('earlier_unmarked') &
                alert.relatedProviderId.isIn(added),
          ))
          .go();
      onChanged?.call();
    });
  }

  Future<bool> readAutoMarkEarlier() async {
    final row =
        await (_record.select(_record.setting)
              ..where((setting) => setting.key.equals(autoMarkEarlierKey)))
            .getSingleOrNull();
    return row?.value == 'true';
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
    int episodes, {
    bool estimated = false,
  }) async {
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
            isEstimated: Value(estimated),
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
