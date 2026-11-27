import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/franchise_scan.dart';
import 'package:konsou/mal/request_gate.dart';

import '../support/franchise_graphs.dart';

final _now = DateTime.utc(2026, 11, 8, 12);
const _day = Duration(days: 1);

/// A saved graph's titles in the shape MAL answers a detail request with.
Map<int, String> buildMalAnswers(String name) => {
  for (final title in readGraphTitles(name))
    title['id'] as int: jsonEncode({
      'id': title['id'],
      'title': title['title'],
      'media_type': title['media_type'],
      'status': title['status'],
      'start_date': title['start_date'],
      'related_anime': [
        for (final relation in readRelations(title))
          {
            'node': {'id': relation['id'], 'title': relation['title']},
            'relation_type': relation['relation_type'],
          },
      ],
    }),
};

void main() {
  late Directory folder;
  late Databases databases;
  late List<int> asked;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_scan_test');
    databases = await openDatabases(folder);
    asked = [];
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  FranchiseScan scanAnswering(
    Map<int, String> answers, {
    int maxChecks = checksPerRun,
  }) => FranchiseScan(
    maxChecks: maxChecks,
    random: Random(7),
    databases: databases,
    detailRequest: DetailRequest(
      clientId: 'test-client',
      client: MockClient((request) async {
        final malId = int.parse(request.url.pathSegments.last);
        asked.add(malId);
        final answer = answers[malId];
        return answer == null
            ? http.Response('', 404)
            : http.Response.bytes(utf8.encode(answer), 200);
      }),
      gate: RequestGate(wait: (_) async {}),
      details: databases.details,
      now: () => _now,
    ),
    now: () => _now,
  );

  Future<void> addEntry(
    String entryId,
    int malId, {
    String status = 'completed',
  }) async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: entryId,
            status: status,
            addedAt: 1,
            progressChangedAt: 1,
          ),
        );
    await record
        .into(record.entryReference)
        .insert(
          EntryReferenceCompanion.insert(
            entryId: entryId,
            provider: 'mal',
            providerId: malId,
          ),
        );
  }

  Future<void> saveDetail(
    Map<int, String> answers,
    int malId, {
    Duration fetchedAgo = Duration.zero,
  }) {
    final details = databases.details;
    return details
        .into(details.detail)
        .insert(
          DetailCompanion.insert(
            provider: 'mal',
            providerId: malId,
            fetchedAt: _now.subtract(fetchedAgo).millisecondsSinceEpoch,
            json: answers[malId]!,
          ),
        );
  }

  Future<Map<String, Map<String, Object?>>> readFranchiseLinks() async => {
    for (final row
        in await databases.details
            .customSelect('SELECT * FROM franchise_link')
            .get())
      row.read<String>('entry_id'): row.data,
  };

  test('seasons not on the list join S1 and S3 into one franchise', () async {
    final danmachi = buildMalAnswers('danmachi');
    await addEntry('s1', 28121);
    await addEntry('s3', 40454);
    await saveDetail(danmachi, 28121);
    await saveDetail(danmachi, 40454);

    await scanAnswering(danmachi).run();

    // the story between and after them; S1 lists the OVA and the movie only
    // as side stories, so they are not fetched
    expect(asked.toSet(), {37347, 47164, 53111, 57066, 63442});
    final franchises = await readFranchiseLinks();
    for (final entry in ['s1', 's3']) {
      expect(franchises[entry], {
        'entry_id': entry,
        'franchise_provider': 'mal',
        'franchise_provider_id': 28121,
        'is_extra': 0,
        'is_placeholder': 0,
      });
    }
  });

  test('an extra on the list joins its franchise as an extra', () async {
    final danmachi = buildMalAnswers('danmachi');
    await addEntry('s1', 28121);
    await addEntry('ova', 40453);
    await saveDetail(danmachi, 28121);
    await saveDetail(danmachi, 40453);

    await scanAnswering(danmachi).run();

    final franchises = await readFranchiseLinks();
    expect(franchises['ova']!['franchise_provider_id'], 28121);
    expect(franchises['ova']!['is_extra'], 1);
  });

  test('an entry with no details keeps its placeholder', () async {
    await addEntry('waiting', 999);
    final details = databases.details;
    await details
        .into(details.franchiseLink)
        .insert(
          FranchiseLinkCompanion.insert(
            entryId: 'waiting',
            franchiseProvider: 'anilist',
            franchiseProviderId: 5,
            isPlaceholder: const Value(true),
          ),
        );

    await scanAnswering(const {}).run();

    expect(
      (await readFranchiseLinks())['waiting']!['franchise_provider'],
      'anilist',
    );
    expect(asked, isEmpty);
  });

  /// The schedule's next check as a number of days from [from], to compare
  /// with an interval and its jitter of up to a fifth.
  double daysFrom(DateTime from, ScanSchedule schedule) =>
      (schedule.nextCheckAt - from.millisecondsSinceEpoch) /
      _day.inMilliseconds;

  test('a franchise with something upcoming is checked in 7 days', () async {
    final danmachi = buildMalAnswers('danmachi');
    await addEntry('s1', 28121);
    await saveDetail(danmachi, 28121);

    await scanAnswering(danmachi).run();

    final details = databases.details;
    final schedule = await details.select(details.scanSchedule).getSingle();
    expect(schedule.providerId, 28121);
    expect(daysFrom(_now, schedule), inInclusiveRange(7, 7 * 1.2));
  });

  test('a new franchise is timed from its last fetch, by its age', () async {
    final steinsGate = buildMalAnswers('steins_gate');
    await addEntry('steins gate', 9253);
    for (final malId in [9253, 10863, 11577]) {
      // the newest story title was fetched ten days ago, which counts
      await saveDetail(steinsGate, malId, fetchedAgo: _day * 10);
    }

    await scanAnswering(steinsGate).run();

    expect(asked, isEmpty);
    final details = databases.details;
    final schedule = await details.select(details.scanSchedule).getSingle();
    final fetched = _now.subtract(_day * 10);
    // ended over six years ago: a year, with up to a fifth added
    expect(daysFrom(fetched, schedule), inInclusiveRange(365, 365 * 1.2));
    expect(schedule.lastCheckAt, fetched.millisecondsSinceEpoch);
  });

  test(
    'a due check fetches the newest story title and sets the next from now',
    () async {
      final steinsGate = buildMalAnswers('steins_gate');
      await addEntry('steins gate', 9253);
      for (final malId in [9253, 10863, 11577]) {
        await saveDetail(steinsGate, malId, fetchedAgo: _day * 400);
      }
      final details = databases.details;
      await details
          .into(details.scanSchedule)
          .insert(
            ScanScheduleCompanion.insert(
              provider: 'mal',
              providerId: 9253,
              lastCheckAt: _now.subtract(_day * 400).millisecondsSinceEpoch,
              nextCheckAt: _now.millisecondsSinceEpoch,
            ),
          );

      await scanAnswering(steinsGate).run();

      expect(asked, [11577]);
      final schedule = await details.select(details.scanSchedule).getSingle();
      expect(schedule.lastCheckAt, _now.millisecondsSinceEpoch);
      expect(daysFrom(_now, schedule), inInclusiveRange(365, 365 * 1.2));
    },
  );

  test(
    'a due franchise whose newest title was fetched lately is not asked again',
    () async {
      final steinsGate = buildMalAnswers('steins_gate');
      await addEntry('steins gate', 9253);
      for (final malId in [9253, 10863, 11577]) {
        await saveDetail(steinsGate, malId, fetchedAgo: _day * 3);
      }
      final details = databases.details;
      await details
          .into(details.scanSchedule)
          .insert(
            ScanScheduleCompanion.insert(
              provider: 'mal',
              providerId: 9253,
              lastCheckAt: _now.subtract(_day * 400).millisecondsSinceEpoch,
              nextCheckAt: _now.subtract(_day).millisecondsSinceEpoch,
            ),
          );

      await scanAnswering(steinsGate).run();

      expect(asked, isEmpty);
      final schedule = await details.select(details.scanSchedule).getSingle();
      expect(
        daysFrom(_now.subtract(_day * 3), schedule),
        inInclusiveRange(365, 365 * 1.2),
      );
    },
  );

  test(
    'a franchise of only Dropped or Not interested titles is never checked',
    () async {
      final steinsGate = buildMalAnswers('steins_gate');
      await addEntry('steins gate', 9253, status: 'dropped');
      for (final malId in [9253, 10863, 11577]) {
        await saveDetail(steinsGate, malId, fetchedAgo: _day * 400);
      }
      final details = databases.details;
      await details
          .into(details.scanSchedule)
          .insert(
            ScanScheduleCompanion.insert(
              provider: 'mal',
              providerId: 9253,
              lastCheckAt: 1,
              nextCheckAt: 2,
            ),
          );

      await scanAnswering(steinsGate).run();

      expect(asked, isEmpty);
      final schedule = await details.select(details.scanSchedule).getSingle();
      expect(schedule.nextCheckAt, 2);
    },
  );

  test(
    'a run makes at most its cap of checks, the longest due first',
    () async {
      final steinsGate = buildMalAnswers('steins_gate');
      final danmachi = buildMalAnswers('danmachi');
      await addEntry('steins gate', 9253);
      await addEntry('danmachi', 28121);
      for (final malId in [9253, 10863, 11577]) {
        await saveDetail(steinsGate, malId, fetchedAgo: _day * 400);
      }
      await saveDetail(danmachi, 28121, fetchedAgo: _day * 400);
      final details = databases.details;
      for (final (id, due) in [(9253, 5), (28121, 3)]) {
        await details
            .into(details.scanSchedule)
            .insert(
              ScanScheduleCompanion.insert(
                provider: 'mal',
                providerId: id,
                lastCheckAt: 1,
                nextCheckAt: _now.subtract(_day * due).millisecondsSinceEpoch,
              ),
            );
      }

      await scanAnswering({...steinsGate, ...danmachi}, maxChecks: 1).run();

      // only the one due longest, Steins;Gate's newest title
      expect(asked.where((malId) => malId == 11577), hasLength(1));
      expect(asked, isNot(contains(28121)));
    },
  );

  test(
    'an extra on the list never pulls in titles through its own relations',
    () async {
      final danmachi = buildMalAnswers('danmachi');
      await addEntry('s1', 28121);
      await addEntry('hot spring ova', 32801);
      await saveDetail(danmachi, 28121);
      await saveDetail(danmachi, 32801);

      await scanAnswering(danmachi).run();

      // the OVA calls Arrow of the Orion its sequel, from its side only
      expect(asked, isNot(contains(37348)));
      expect((await readFranchiseLinks())['hot spring ova']!['is_extra'], 1);
    },
  );

  test(
    'a changed check fetches the new story title and times by the new one',
    () async {
      final steinsGate = buildMalAnswers('steins_gate');
      await addEntry('steins gate', 9253);
      for (final malId in [9253, 10863, 11577]) {
        await saveDetail(steinsGate, malId, fetchedAgo: _day * 400);
      }
      final details = databases.details;
      await details
          .into(details.scanSchedule)
          .insert(
            ScanScheduleCompanion.insert(
              provider: 'mal',
              providerId: 9253,
              lastCheckAt: 1,
              nextCheckAt: _now.millisecondsSinceEpoch,
            ),
          );
      // MAL now lists an upcoming sequel on the movie, and the sequel lists it back
      final movie = jsonDecode(steinsGate[11577]!) as Map<String, dynamic>;
      (movie['related_anime'] as List).add({
        'node': {'id': 99999, 'title': 'Upcoming sequel'},
        'relation_type': 'sequel',
      });
      final answers = {
        ...steinsGate,
        11577: jsonEncode(movie),
        99999: jsonEncode({
          'id': 99999,
          'title': 'Upcoming sequel',
          'media_type': 'tv',
          'status': 'not_yet_aired',
          'start_date': null,
          'related_anime': [
            {
              'node': {'id': 11577, 'title': 'movie'},
              'relation_type': 'prequel',
            },
          ],
        }),
      };

      await scanAnswering(answers).run();

      expect(asked, [11577, 99999]);
      final schedule = await details.select(details.scanSchedule).getSingle();
      expect(daysFrom(_now, schedule), inInclusiveRange(7, 7 * 1.2));
    },
  );

  test('the wait between checks follows how long ago the title ended', () {
    Duration wait({bool airing = false, String? endedOn}) =>
        getRecheckInterval(airing: airing, endedOn: endedOn, now: _now);
    expect(wait(airing: true, endedOn: '2020-01-01'), _day * 7);
    expect(wait(endedOn: '2026-06-01'), _day * 30);
    expect(wait(endedOn: '2025-06'), _day * 90);
    expect(wait(endedOn: '2022-01-01'), _day * 180);
    expect(wait(endedOn: '2013'), _day * 365);
    expect(wait(), _day * 90);
  });
}
