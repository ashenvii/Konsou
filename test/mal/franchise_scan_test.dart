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

  FranchiseScan scanAnswering(Map<int, String> answers) => FranchiseScan(
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

  Future<void> addEntry(String entryId, int malId) async {
    final record = databases.record;
    await record
        .into(record.entry)
        .insert(
          EntryCompanion.insert(
            entryId: entryId,
            status: 'completed',
            addedAt: 1,
            updatedAt: 1,
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

  Future<void> saveDetail(Map<int, String> answers, int malId) {
    final details = databases.details;
    return details
        .into(details.detail)
        .insert(
          DetailCompanion.insert(
            provider: 'mal',
            providerId: malId,
            fetchedAt: _now.millisecondsSinceEpoch,
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

  test(
    'a new franchise with something upcoming is checked in 7 days',
    () async {
      final danmachi = buildMalAnswers('danmachi');
      await addEntry('s1', 28121);
      await saveDetail(danmachi, 28121);

      await scanAnswering(danmachi).run();

      final details = databases.details;
      final schedule = await details.select(details.scanSchedule).getSingle();
      expect(schedule.providerId, 28121);
      expect(schedule.quietStreak, 0);
      expect(schedule.nextCheckAt, _now.add(_day * 7).millisecondsSinceEpoch);
    },
  );

  test('a due check fetches the newest story title and backs off when nothing changed', () async {
    final steinsGate = buildMalAnswers('steins_gate');
    await addEntry('steins gate', 9253);
    for (final malId in [9253, 10863, 11577]) {
      await saveDetail(steinsGate, malId);
    }
    final details = databases.details;
    await details
        .into(details.scanSchedule)
        .insert(
          ScanScheduleCompanion.insert(
            provider: 'mal',
            providerId: 9253,
            lastCheckAt: _now.subtract(_day * 14).millisecondsSinceEpoch,
            nextCheckAt: _now.millisecondsSinceEpoch,
            quietStreak: const Value(1),
          ),
        );

    await scanAnswering(steinsGate).run();

    expect(asked, [11577]);
    final schedule = await details.select(details.scanSchedule).getSingle();
    expect(schedule.quietStreak, 2);
    expect(schedule.lastCheckAt, _now.millisecondsSinceEpoch);
    expect(schedule.nextCheckAt, _now.add(_day * 28).millisecondsSinceEpoch);
  });

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

  test('a changed check starts over and fetches the new story title', () async {
    final steinsGate = buildMalAnswers('steins_gate');
    await addEntry('steins gate', 9253);
    for (final malId in [9253, 10863, 11577]) {
      await saveDetail(steinsGate, malId);
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
            quietStreak: const Value(3),
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
    expect(schedule.quietStreak, 0);
    expect(schedule.nextCheckAt, _now.add(_day * 7).millisecondsSinceEpoch);
  });

  test('the wait between checks', () {
    expect(getRecheckInterval(airing: true, quietStreak: 6), _day * 7);
    expect([
      for (var streak = 0; streak <= 6; streak++)
        getRecheckInterval(airing: false, quietStreak: streak),
    ], [7, 14, 28, 56, 90, 90, 90].map((days) => _day * days));
  });
}
