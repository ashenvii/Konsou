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
  final years = now.difference(ended).inDays / 365;
  return Duration(
    days: years < 1
        ? 30
        : years < 3
        ? 90
        : years < 6
        ? 180
        : 365,
  );
}

class FranchiseScan {
  FranchiseScan({
    required this.databases,
    required this.detailRequest,
    this.maxChecks = checksPerRun,
    Random? random,
    DateTime Function()? now,
  }) : _random = random ?? Random(),
       _now = now ?? DateTime.now;

  final Databases databases;
  final DetailRequest detailRequest;
  final int maxChecks;
  final Random _random;
  final DateTime Function() _now;

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
      // nobody waits for a sequel to something dropped
      if (!state.followedFranchises.contains(row.providerId)) continue;
      final newest = state.findNewestStoryTitle(row.providerId);
      if (newest == null) continue;
      final interval = state.getInterval(row.providerId, newest, now);
      // a fetch by any other route is as good as a check
      final fetched = DateTime.fromMillisecondsSinceEpoch(
        state.titles[newest]!.fetchedAt,
      );
      if (now.difference(fetched) < interval) {
        await _writeSchedule(row.providerId, from: fetched, interval: interval);
        continue;
      }
      if (checks == maxChecks) break;
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
      await _writeSchedule(
        row.providerId,
        from: now,
        interval: changed ? const Duration(days: 7) : interval,
      );
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
        final now = _now();
        await _writeSchedule(
          franchiseId,
          from: newest == null
              ? now
              : DateTime.fromMillisecondsSinceEpoch(
                  state.titles[newest]!.fetchedAt,
                ),
          interval: state.getInterval(franchiseId, newest, now),
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
  Future<void> _writeSchedule(
    int franchiseId, {
    required DateTime from,
    required Duration interval,
  }) {
    final wait = Duration(
      milliseconds: (interval.inMilliseconds * (1 + _random.nextDouble() * 0.2))
          .round(),
    );
    return databases.record.customStatement(
      '''
      INSERT OR REPLACE INTO details.scan_schedule
        (provider, provider_id, last_check_at, next_check_at)
      VALUES ('mal', ?, ?, ?)
      ''',
      [
        franchiseId,
        from.millisecondsSinceEpoch,
        from.add(wait).millisecondsSinceEpoch,
      ],
    );
  }

  Future<_ScanState> _load() async {
    final record = databases.record;
    final titles = await readSavedTitles(record);
    final malIdsByEntry = {
      for (final row in await record.customSelect('''
        SELECT entry_reference.entry_id, entry_reference.provider_id
        FROM entry_reference JOIN entry USING (entry_id)
        WHERE entry_reference.provider = 'mal'
      ''').get())
        row.read<String>('entry_id'): row.read<int>('provider_id'),
    };
    final idleIds = {
      for (final row in await record.customSelect('''
        SELECT entry_reference.provider_id
        FROM entry_reference JOIN entry USING (entry_id)
        WHERE entry_reference.provider = 'mal'
          AND entry.status IN ('dropped', 'not_interested')
      ''').get())
        row.read<int>('provider_id'),
    };
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
  _ScanState({
    required this.titles,
    required this.places,
    required this.malIdsByEntry,
    required this.idleIds,
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

  /// The list's titles whose entry is Dropped or Not interested.
  final Set<int> idleIds;

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

  /// The wait before a franchise's newest story title is looked at again.
  Duration getInterval(int franchiseId, int? newest, DateTime now) {
    final saved = newest == null ? null : titles[newest];
    return getRecheckInterval(
      airing: isAiring(franchiseId),
      now: now,
      endedOn: saved?.endDate ?? saved?.title.startDate,
    );
  }
}
