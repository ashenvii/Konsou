import 'dart:math';

import 'package:drift/drift.dart';

import '../data/databases.dart';
import 'detail_request.dart';
import 'franchise_grouping.dart';
import 'request_gate.dart';
import 'saved_titles.dart';

/// The most checks one run makes, longest due first; the rest wait for the
/// next launch.
const checksPerRun = 100;

/// How long a franchise goes before its newest story title is looked at
/// again: a week while anything in it airs or is announced, then longer the
/// longer ago it ended, since a sequel is least likely for an old one. With no
/// date at all, 90 days.
Duration getRecheckInterval({
  required bool airing,
  required DateTime now,
  String? endedOn,
}) {
  if (airing) return const Duration(days: 7);
  final ended = switch (endedOn?.length) {
    4 => DateTime.tryParse('$endedOn-01-01T00:00:00Z'),
    7 => DateTime.tryParse('$endedOn-01T00:00:00Z'),
    10 => DateTime.tryParse('${endedOn}T00:00:00Z'),
    _ => null,
  };
  if (ended == null) return const Duration(days: 90);
  return Duration(
    days: switch (now.difference(ended).inDays / 365) {
      < 1 => 30,
      < 3 => 90,
      < 6 => 180,
      _ => 365,
    },
  );
}

/// When a franchise was last looked at and how long until the next look.
typedef _Check = ({DateTime from, Duration interval});

class FranchiseScan {
  FranchiseScan({
    required this.databases,
    required this.detailRequest,
    this.maxChecks = checksPerRun,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Databases databases;
  final DetailRequest detailRequest;
  final int maxChecks;
  final DateTime Function() _now;
  final _random = Random();

  Future<void> run() async {
    var state = await _walk();
    if (await _checkDue(state)) state = await _walk();
    await _save(state);
  }

  Future<_ScanState> _walk() async {
    final failed = <int>{};
    while (true) {
      final state = await _load();
      final onList = state.malIdsByEntry.values.toSet();
      final missing =
          {
            for (final saved in state.titles.values)
              for (final relation in saved.title.relations)
                if ((state.isStoryInListFranchise(saved.title.id) &&
                        storyRelations.contains(relation.type)) ||
                    (onList.contains(saved.title.id) &&
                        parentRelations[relation.type] == true))
                  relation.id,
          }..removeWhere(
            (malId) =>
                state.titles.containsKey(malId) ||
                state.gone.contains(malId) ||
                failed.contains(malId),
          );
      if (missing.isEmpty) return state;
      for (final malId in missing) {
        if (detailRequest.gate.isBackingOffLong) return state;
        final outcome = await detailRequest.fetch(
          malId,
          lane: Lane.trickle,
          full: false,
        );
        if (outcome.didFail) failed.add(malId);
      }
    }
  }

  Future<bool> _checkDue(_ScanState state) async {
    final details = databases.details;
    final now = _now();
    final due =
        await (details.select(details.scanSchedule)
              ..where(
                (row) => row.nextCheckAt.isSmallerOrEqualValue(
                  now.millisecondsSinceEpoch,
                ),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.nextCheckAt)]))
            .get();
    var checks = 0;
    var anyChanged = false;
    for (final row in due) {
      final franchiseId = row.providerId;
      // nobody waits for a sequel to something dropped
      if (!state.followedFranchises.contains(franchiseId)) continue;
      final newest = state.findNewestStoryTitle(franchiseId);
      if (newest == null) continue;
      final last = state.findLastCheck(franchiseId, newest, now);
      // a fetch by any other route is as good as a check
      if (now.difference(last.from) < last.interval) {
        await _writeSchedule(franchiseId, last);
        continue;
      }
      if (checks == maxChecks || detailRequest.gate.isBackingOffLong) break;
      checks++;
      final outcome = await detailRequest.fetch(
        newest,
        lane: Lane.trickle,
        full: false,
      );
      if (outcome.didFail) continue;
      final before = _relationIds(state.titles[newest]);
      final after = _relationIds(
        (await readSavedTitles(databases.record, malId: newest))[newest],
      );
      final changed =
          before.length != after.length || !before.containsAll(after);
      anyChanged = anyChanged || changed;
      // a new sequel is looked at again in a week, once its title is saved
      await _writeSchedule(franchiseId, (
        from: now,
        interval: changed ? const Duration(days: 7) : last.interval,
      ));
    }
    return anyChanged;
  }

  Future<void> _save(_ScanState state) async {
    final record = databases.record;
    final scheduled = {
      for (final row
          in await record
              .customSelect(
                "SELECT provider_id FROM details.scan_schedule WHERE provider = 'mal'",
              )
              .get())
        row.read<int>('provider_id'),
    };
    final now = _now();
    await record.transaction(() async {
      for (final MapEntry(key: entryId, value: malId)
          in state.malIdsByEntry.entries) {
        final place = state.places[malId];
        if (place == null) continue;
        await record.customStatement(
          '''
          INSERT OR REPLACE INTO details.franchise_link
            (entry_id, franchise_provider, franchise_provider_id, is_extra, is_placeholder)
          VALUES (?, 'mal', ?, ?, 0)
          ''',
          [entryId, place.franchiseId, place.isExtra ? 1 : 0],
        );
      }
      // rows for removed entries and franchises would otherwise linger
      await record.customStatement(
        'DELETE FROM details.franchise_link WHERE entry_id NOT IN (SELECT entry_id FROM entry)',
      );
      final franchises = state.listFranchises;
      for (final franchiseId in franchises.difference(scheduled)) {
        // the fetch that found the franchise counts as its first check
        final newest = state.findNewestStoryTitle(franchiseId);
        await _writeSchedule(
          franchiseId,
          state.findLastCheck(franchiseId, newest, now),
        );
      }
      for (final franchiseId in scheduled.difference(franchises)) {
        await record.customStatement(
          "DELETE FROM details.scan_schedule WHERE provider = 'mal' AND provider_id = ?",
          [franchiseId],
        );
      }
    });
  }

  // through the record connection, to join the transaction open there; up to
  // a fifth is added, so franchises and installs do not all fall due together
  Future<void> _writeSchedule(int franchiseId, _Check check) {
    final wait = check.interval * (1 + _random.nextDouble() * 0.2);
    return databases.record.customStatement(
      '''
      INSERT OR REPLACE INTO details.scan_schedule
        (provider, provider_id, last_check_at, next_check_at)
      VALUES ('mal', ?, ?, ?)
      ''',
      [
        franchiseId,
        check.from.millisecondsSinceEpoch,
        check.from.add(wait).millisecondsSinceEpoch,
      ],
    );
  }

  Future<_ScanState> _load() async {
    final record = databases.record;
    final titles = await readSavedTitles(record);
    final malIdsByEntry = <String, int>{};
    final idleIds = <int>{};
    for (final row in await record.customSelect('''
      SELECT entry_reference.entry_id, entry_reference.provider_id, entry.status
      FROM entry_reference JOIN entry USING (entry_id)
      WHERE entry_reference.provider = 'mal'
    ''').get()) {
      final malId = row.read<int>('provider_id');
      malIdsByEntry[row.read<String>('entry_id')] = malId;
      final status = row.read<String>('status');
      if (status == 'dropped' || status == 'not_interested') idleIds.add(malId);
    }
    final gone = await readGonePages(record, _now());
    return _ScanState(
      titles: titles,
      places: groupFranchises(titles.values.map((saved) => saved.title)),
      malIdsByEntry: malIdsByEntry,
      idleIds: idleIds,
      gone: gone,
    );
  }
}

Set<int> _relationIds(SavedTitle? saved) => {
  for (final relation in saved?.title.relations ?? const <TitleRelation>[])
    relation.id,
};

class _ScanState {
  /// [idleIds] are the list's titles whose entry is Dropped or Not interested.
  _ScanState({
    required this.titles,
    required this.places,
    required this.malIdsByEntry,
    required Set<int> idleIds,
    required this.gone,
  }) : listFranchises = {
         for (final malId in malIdsByEntry.values) ?places[malId]?.franchiseId,
       },
       followedFranchises = {
         for (final malId in malIdsByEntry.values)
           if (!idleIds.contains(malId)) ?places[malId]?.franchiseId,
       };

  final Map<int, SavedTitle> titles;
  final Map<int, FranchisePlace> places;
  final Map<String, int> malIdsByEntry;
  final Set<int> gone;

  final Set<int> listFranchises;

  /// Franchises with a title on the list that is not Dropped or Not interested.
  final Set<int> followedFranchises;

  bool isStoryInListFranchise(int malId) {
    final place = places[malId];
    return place != null &&
        !place.isExtra &&
        listFranchises.contains(place.franchiseId);
  }

  Iterable<int> findMembers(int franchiseId) => [
    for (final MapEntry(key: malId, value: place) in places.entries)
      if (place.franchiseId == franchiseId) malId,
  ];

  bool isAiring(int franchiseId) => findMembers(franchiseId)
      .any((malId) => changingStatuses.contains(titles[malId]?.airingStatus));

  int? findNewestStoryTitle(int franchiseId) => sortByStart([
    for (final malId in findMembers(franchiseId))
      if (!places[malId]!.isExtra) titles[malId]!.title,
  ]).lastOrNull?.id;

  /// The last fetch of the franchise's [newest] story title ([now] when it has
  /// none), and the wait from there by how long ago that title ended.
  _Check findLastCheck(int franchiseId, int? newest, DateTime now) {
    final saved = newest == null ? null : titles[newest];
    return (
      from: saved == null
          ? now
          : DateTime.fromMillisecondsSinceEpoch(saved.fetchedAt),
      interval: getRecheckInterval(
        airing: isAiring(franchiseId),
        now: now,
        endedOn: saved?.endDate ?? saved?.title.startDate,
      ),
    );
  }
}
