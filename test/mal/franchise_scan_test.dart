import 'dart:convert';
import 'dart:io';

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
    bool offline = false,
  }) => FranchiseScan(
    maxChecks: maxChecks,
    databases: databases,
    detailRequest: DetailRequest(
      clientId: 'test-client',
      client: MockClient((request) async {
        final malId = int.parse(request.url.pathSegments.last);
        asked.add(malId);
        if (offline) throw const SocketException('offline');
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

  Future<ScanSchedule> readSchedule() =>
      databases.details.select(databases.details.scanSchedule).getSingle();

  Future<void> scheduleCheck(int franchiseId, DateTime next) => databases
      .details
      .into(databases.details.scanSchedule)
      .insert(
        ScanScheduleCompanion.insert(
          provider: 'mal',
          providerId: franchiseId,
          lastCheckAt: 1,
          nextCheckAt: next.millisecondsSinceEpoch,
        ),
      );

  /// Steins;Gate on the list: the series, its sequel and the movie, saved.
  Future<Map<int, String>> saveSteinsGate(
    Duration fetchedAgo, {
    String status = 'completed',
  }) async {
    final steinsGate = buildMalAnswers('steins_gate');
    await addEntry('steins gate', 9253, status: status);
    for (final malId in [9253, 10863, 11577]) {
      await saveDetail(steinsGate, malId, fetchedAgo: fetchedAgo);
    }
    return steinsGate;
  }

  test('a franchise with something upcoming is checked in 7 days', () async {
    final danmachi = buildMalAnswers('danmachi');
    await addEntry('s1', 28121);
    await saveDetail(danmachi, 28121);

    await scanAnswering(danmachi).run();

    final schedule = await readSchedule();
    expect(schedule.providerId, 28121);
    expect(daysFrom(_now, schedule), inInclusiveRange(7, 7 * 1.2));
  });

  test('a new franchise is timed from its last fetch, by its age', () async {
    // the newest story title was fetched ten days ago, which counts
    final steinsGate = await saveSteinsGate(_day * 10);

    await scanAnswering(steinsGate).run();

    expect(asked, isEmpty);
    final schedule = await readSchedule();
    final fetched = _now.subtract(_day * 10);
    // ended over six years ago: a year, with up to a fifth added
    expect(daysFrom(fetched, schedule), inInclusiveRange(365, 365 * 1.2));
    expect(schedule.lastCheckAt, fetched.millisecondsSinceEpoch);
  });

  test(
    'a due check fetches the newest story title and sets the next from now',
    () async {
      final steinsGate = await saveSteinsGate(_day * 400);
      await scheduleCheck(9253, _now);

      await scanAnswering(steinsGate).run();

      expect(asked, [11577]);
      final schedule = await readSchedule();
      expect(schedule.lastCheckAt, _now.millisecondsSinceEpoch);
      expect(daysFrom(_now, schedule), inInclusiveRange(365, 365 * 1.2));
    },
  );

  test(
    'a due franchise whose newest title was fetched lately is not asked again',
    () async {
      final steinsGate = await saveSteinsGate(_day * 3);
      await scheduleCheck(9253, _now.subtract(_day));

      await scanAnswering(steinsGate).run();

      expect(asked, isEmpty);
      expect(
        daysFrom(_now.subtract(_day * 3), await readSchedule()),
        inInclusiveRange(365, 365 * 1.2),
      );
    },
  );

  test(
    'a franchise of only Dropped or Not interested titles is never checked',
    () async {
      final steinsGate = await saveSteinsGate(_day * 400, status: 'dropped');
      final due = _now.subtract(_day);
      await scheduleCheck(9253, due);

      await scanAnswering(steinsGate).run();

      expect(asked, isEmpty);
      expect((await readSchedule()).nextCheckAt, due.millisecondsSinceEpoch);
    },
  );

  test(
    'a run makes at most its cap of checks, the longest due first',
    () async {
      final steinsGate = await saveSteinsGate(_day * 400);
      final danmachi = buildMalAnswers('danmachi');
      await addEntry('danmachi', 28121);
      await saveDetail(danmachi, 28121, fetchedAgo: _day * 400);
      await scheduleCheck(9253, _now.subtract(_day * 5));
      await scheduleCheck(28121, _now.subtract(_day * 3));

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
      final steinsGate = await saveSteinsGate(_day * 400);
      await scheduleCheck(9253, _now);
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
      expect(
        daysFrom(_now, await readSchedule()),
        inInclusiveRange(7, 7 * 1.2),
      );
    },
  );

  group(
    'offline, the scan stops once the gate backs off past its first step',
    () {
      // three titles of their own, fetched long ago, each naming a sequel MAL
      // has not been asked for when [sequels]
      Future<Map<int, String>> saveStandalones({required bool sequels}) async {
        final answers = {
          for (final malId in [1, 2, 3])
            malId: jsonEncode({
              'id': malId,
              'title': 'Title $malId',
              'media_type': 'tv',
              'status': 'finished_airing',
              'start_date': '2010-01-01',
              'related_anime': [
                if (sequels)
                  {
                    'node': {'id': malId + 100, 'title': 'Sequel'},
                    'relation_type': 'sequel',
                  },
              ],
            }),
        };
        for (final malId in answers.keys) {
          await addEntry('entry $malId', malId);
          await saveDetail(answers, malId, fetchedAgo: _day * 400);
        }
        return answers;
      }

      test('in the walk', () async {
        final answers = await saveStandalones(sequels: true);

        await scanAnswering(answers, offline: true).run();

        // the second failure in a row doubles the gate's wait
        expect(asked, [101, 102]);
      });

      test('in the checks', () async {
        final answers = await saveStandalones(sequels: false);
        for (final malId in answers.keys) {
          await scheduleCheck(malId, _now);
        }

        await scanAnswering(answers, offline: true).run();

        expect(asked, [1, 2]);
      });
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
