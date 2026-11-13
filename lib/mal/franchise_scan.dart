import 'dart:math';

import 'package:drift/drift.dart';

import '../data/databases.dart';
import 'detail_request.dart';
import 'franchise_grouping.dart';
import 'request_gate.dart';
import 'saved_titles.dart';

Duration getRecheckInterval({required bool airing, required int quietStreak}) {
  if (airing) return const Duration(days: 7);
  final days = 7 * pow(2, min(quietStreak, 5));
  return Duration(days: min(days.toInt(), 90));
}

class FranchiseScan {
  FranchiseScan({
    required this.databases,
    required this.detailRequest,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Databases databases;
  final DetailRequest detailRequest;
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
    final now = _now().millisecondsSinceEpoch;
    final due = await (details.select(
      details.scanSchedule,
    )..where((row) => row.nextCheckAt.isSmallerOrEqualValue(now))).get();
    var anyChanged = false;
    for (final row in due) {
      final newest = state.findNewestStoryTitle(row.providerId);
      if (newest == null) continue;
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
      final airing = state.isAiring(row.providerId);
      // the doubling starts over once airing ends, so a finale is followed up
      await _writeSchedule(
        row.providerId,
        quietStreak: changed || airing ? 0 : row.quietStreak + 1,
        airing: airing,
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
        await _writeSchedule(
          franchiseId,
          quietStreak: 0,
          airing: state.isAiring(franchiseId),
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

  // through the record connection, to join the transaction open there
  Future<void> _writeSchedule(
    int franchiseId, {
    required int quietStreak,
    required bool airing,
  }) {
    final now = _now();
    return databases.record.customStatement(
      '''
      INSERT OR REPLACE INTO details.scan_schedule
        (provider, provider_id, last_check_at, next_check_at, quiet_streak)
      VALUES ('mal', ?, ?, ?, ?)
      ''',
      [
        franchiseId,
        now.millisecondsSinceEpoch,
        now
            .add(getRecheckInterval(airing: airing, quietStreak: quietStreak))
            .millisecondsSinceEpoch,
        quietStreak,
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
    final gone = {
      for (final row
          in await record
              .customSelect(
                "SELECT provider_id FROM details.gone_page WHERE provider = 'mal' AND checked_at > ?",
                variables: [
                  Variable.withInt(
                    _now().subtract(goneRecheck).millisecondsSinceEpoch,
                  ),
                ],
              )
              .get())
        row.read<int>('provider_id'),
    };
    return _ScanState(
      titles: titles,
      places: groupFranchises(titles.values.map((saved) => saved.title)),
      malIdsByEntry: malIdsByEntry,
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
    required this.gone,
  }) : listFranchises = {
         for (final malId in malIdsByEntry.values) ?places[malId]?.franchiseId,
       };

  final Map<int, SavedTitle> titles;
  final Map<int, FranchisePlace> places;
  final Map<String, int> malIdsByEntry;
  final Set<int> gone;

  final Set<int> listFranchises;

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
}
