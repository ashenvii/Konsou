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
import 'package:konsou/mal/matching.dart';
import 'package:konsou/mal/request_gate.dart';
import 'package:konsou/mal/search_request.dart';
import 'package:konsou/search/title_tree.dart';

final _now = DateTime.utc(2026, 11, 8, 12);

/// A search result in the shape MAL sends.
Map<String, dynamic> buildNode(
  int id,
  String title, {
  String en = '',
  List<String> synonyms = const [],
  int episodes = 0,
}) => {
  'id': id,
  'title': title,
  'alternative_titles': {'synonyms': synonyms, 'en': en, 'ja': ''},
  'media_type': 'tv',
  'num_episodes': episodes,
};

void main() {
  test('searches the name, then without brackets, then before the colon', () {
    expect(buildMatchQueries('THE Big O (2003)'), [
      'THE Big O (2003)',
      'THE Big O',
    ]);
    expect(
      buildMatchQueries(
        'Shingeki no Kyojin: The Final Season - Kanketsu-hen Kouhen',
      ),
      [
        'Shingeki no Kyojin: The Final Season - Kanketsu-hen Kouhen',
        'Shingeki no Kyojin',
      ],
    );
    expect(buildMatchQueries('Fate/strange Fake - Whispers (Zoku-hen)'), [
      'Fate/strange Fake - Whispers (Zoku-hen)',
      'Fate/strange Fake - Whispers',
      'Fate/strange Fake',
    ]);
    expect(buildMatchQueries('Re: Hi (TV)'), ['Re: Hi (TV)', 'Re: Hi']);
    expect(buildMatchQueries('Hi'), isEmpty);
  });

  group('with databases', () {
    late Directory folder;
    late Databases databases;
    late Map<String, List<Map<String, dynamic>>> searches;
    late List<String> asked;
    late int searchStatus;

    setUp(() async {
      folder = Directory.systemTemp.createTempSync('konsou_matching_test');
      databases = await openDatabases(folder);
      searches = {};
      asked = [];
      searchStatus = 200;
    });

    tearDown(() async {
      await databases.close();
      folder.deleteSync(recursive: true);
    });

    Matching buildMatching({DateTime? now}) {
      final client = MockClient((request) async {
        final segments = request.url.pathSegments;
        if (segments.last == 'anime') {
          final query = request.url.queryParameters['q']!;
          asked.add(query);
          if (searchStatus != 200) return http.Response('', searchStatus);
          final data = [
            for (final node in searches[query] ?? []) {'node': node},
          ];
          return http.Response.bytes(
            utf8.encode(jsonEncode({'data': data})),
            200,
          );
        }
        asked.add('detail ${segments.last}');
        return http.Response(
          '{"id": ${segments.last}, "title": "fetched"}',
          200,
        );
      });
      final gate = RequestGate(wait: (_) async {});
      return Matching(
        databases: databases,
        searchRequest: SearchRequest(
          clientId: 'test-client',
          client: client,
          gate: gate,
        ),
        detailRequest: DetailRequest(
          clientId: 'test-client',
          client: client,
          gate: gate,
          details: databases.details,
          now: () => now ?? _now,
        ),
        now: () => now ?? _now,
      );
    }

    Future<void> addEntry(
      String entryId,
      String? name, {
      int? malId,
      int watched = 0,
      String status = 'plan_to_watch',
      int updatedAt = 1,
    }) async {
      final record = databases.record;
      await record
          .into(record.entry)
          .insert(
            EntryCompanion.insert(
              entryId: entryId,
              name: Value(name),
              status: status,
              episodesWatched: Value(watched),
              addedAt: 1,
              progressChangedAt: updatedAt,
            ),
          );
      if (malId == null) return;
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

    Future<int?> readMalId(String entryId) async {
      final record = databases.record;
      final row =
          await (record.select(record.entryReference)..where(
                (ref) =>
                    ref.entryId.equals(entryId) & ref.provider.equals('mal'),
              ))
              .getSingleOrNull();
      return row?.providerId;
    }

    Future<List<int>> readSuggestions(String entryId) async {
      final details = databases.details;
      final rows =
          await (details.select(details.matchSuggestion)
                ..where((row) => row.entryId.equals(entryId))
                ..orderBy([(row) => OrderingTerm(expression: row.position)]))
              .get();
      return [for (final row in rows) row.providerId];
    }

    Future<bool> hasAttempt(String entryId) async {
      final details = databases.details;
      final row = await (details.select(
        details.matchAttempt,
      )..where((row) => row.entryId.equals(entryId))).getSingleOrNull();
      return row != null;
    }

    test('links by itself when exactly one title is the name', () async {
      await addEntry('hi', 'Hi-DRIVERS');
      searches['Hi-DRIVERS'] = [
        buildNode(53525, 'Hi-DRIVERS!'),
        buildNode(50071, 'Drivers License'),
      ];

      final outcome = await buildMatching().matchEntry('hi');

      expect(outcome, MatchOutcome.linked);
      expect(await readMalId('hi'), 53525);
      expect(asked, ['Hi-DRIVERS', 'detail 53525']);
      expect(await readSuggestions('hi'), isEmpty);
      expect(await hasAttempt('hi'), isFalse);
    });

    test('a synonym or english title counts as the name', () async {
      await addEntry('bocchi', 'Bocchi the Rock! Re:Re:');
      searches['Bocchi the Rock! Re:Re:'] = [
        buildNode(47917, 'Bocchi the Rock!'),
        buildNode(
          55357,
          'Bocchi the Rock! Movie',
          synonyms: ['Bocchi the Rock! Re:', 'Bocchi the Rock! Re:Re:'],
          episodes: 2,
        ),
      ];

      expect(await buildMatching().matchEntry('bocchi'), MatchOutcome.linked);
      expect(await readMalId('bocchi'), 55357);
    });

    test('offers instead when the page is used by another entry', () async {
      await addEntry('re', 'Bocchi the Rock! Re:', malId: 55357);
      await addEntry('rere', 'Bocchi the Rock! Re:Re:');
      searches['Bocchi the Rock! Re:Re:'] = [
        buildNode(47917, 'Bocchi the Rock!'),
        buildNode(
          55357,
          'Bocchi the Rock! Movie',
          synonyms: ['Bocchi the Rock! Re:', 'Bocchi the Rock! Re:Re:'],
        ),
      ];

      final outcome = await buildMatching().matchEntry('rere');

      expect(outcome, MatchOutcome.suggested);
      expect(await readMalId('rere'), isNull);
      expect(await readSuggestions('rere'), [55357, 47917]);
      expect(await hasAttempt('rere'), isTrue);
    });

    test(
      'offers instead when more episodes were watched than the page has',
      () async {
        await addEntry('fox', 'Fox Spirit Matchmaker', watched: 24);
        searches['Fox Spirit Matchmaker'] = [
          buildNode(
            31499,
            'Huyao Xiao Hongniang 1: Xia Sha Pian',
            en: 'Fox Spirit Matchmaker',
            episodes: 13,
          ),
        ];

        expect(await buildMatching().matchEntry('fox'), MatchOutcome.suggested);
        expect(await readSuggestions('fox'), [31499]);
      },
    );

    test('two titles equal to the name are both offered', () async {
      await addEntry('youko', 'Enmusubi no Youko-chan');
      searches['Enmusubi no Youko-chan'] = [
        buildNode(
          31499,
          'Huyao Xiao Hongniang 1',
          synonyms: ['Enmusubi no Youko-chan'],
        ),
        buildNode(
          36823,
          'Huyao Xiao Hongniang 3',
          synonyms: ['Enmusubi no Youko-chan'],
        ),
      ];

      expect(await buildMatching().matchEntry('youko'), MatchOutcome.suggested);
      expect(await readSuggestions('youko'), [31499, 36823]);
    });

    test(
      'drops results that share too few words and tries shorter queries',
      () async {
        await addEntry('angels', 'Angels of Death (ONA)');
        searches['Angels of Death (ONA)'] = [];
        searches['Angels of Death'] = [
          buildNode(40000, 'Death Note'),
          buildNode(35994, 'Satsuriku no Tenshi', en: 'Angels of Death'),
          buildNode(41000, 'Angel Beats!'),
        ];

        expect(
          await buildMatching().matchEntry('angels'),
          MatchOutcome.suggested,
        );
        expect(asked, ['Angels of Death (ONA)', 'Angels of Death']);
        // death note shares half the words; angel beats is one typo away
        expect(await readSuggestions('angels'), [35994, 40000]);
      },
    );

    test('a name of only short words counts them all', () async {
      await addEntry('bigo', 'The Big O II');
      searches['The Big O II'] = [
        buildNode(62893, 'Nigashita Sakana wa Ookikatta'),
        buildNode(567, 'The Big O'),
        buildNode(61039, 'Hoshi no Kodomo', en: 'Sora and the Big Tree'),
      ];

      expect(await buildMatching().matchEntry('bigo'), MatchOutcome.suggested);
      expect(await readSuggestions('bigo'), [567, 61039]);
    });

    test('nothing close is nothing, and the try is remembered', () async {
      await addEntry('iris', 'IRIS OUT');
      searches['IRIS OUT'] = [
        buildNode(21663, 'Last Orders'),
        buildNode(33897, 'Utsukushii Chikyuu wo Yogosanai de'),
      ];

      expect(await buildMatching().matchEntry('iris'), MatchOutcome.nothing);
      expect(await readSuggestions('iris'), isEmpty);
      expect(await hasAttempt('iris'), isTrue);
    });

    test('small words and typos do not count toward a suggestion', () async {
      await addEntry('iris', 'IRIS OUT');
      searches['IRIS OUT'] = [
        buildNode(21663, 'Last Orders', synonyms: ["Murphy's Irish Stout"]),
        buildNode(43205, 'Gundam', en: 'Love That Cries Out in Battle'),
      ];
      await addEntry('koro', 'Koro-sensei Q!');
      searches['Koro-sensei Q!'] = [buildNode(34389, 'Koro-sensei Quest!')];

      final matching = buildMatching();
      expect(await matching.matchEntry('iris'), MatchOutcome.nothing);
      expect(await matching.matchEntry('koro'), MatchOutcome.suggested);
      expect(await readSuggestions('koro'), [34389]);
    });

    test('a declined page is never offered or linked again', () async {
      await addEntry('hi', 'Hi-DRIVERS');
      searches['Hi-DRIVERS'] = [
        buildNode(53525, 'Hi-DRIVERS!'),
        buildNode(53526, 'Hi-DRIVERS Two'),
      ];
      final matching = buildMatching();
      await matching.matchEntry('hi');
      await matching.unlinkEntry('hi');

      expect(await readMalId('hi'), isNull);
      expect(await matching.matchEntry('hi'), MatchOutcome.suggested);
      expect(await readSuggestions('hi'), [53526]);

      await matching.declineSuggestions('hi');
      expect(await readSuggestions('hi'), isEmpty);
      expect(await matching.matchEntry('hi'), MatchOutcome.nothing);
      final record = databases.record;
      final declined = await record.select(record.matchDecline).get();
      expect(declined.map((row) => row.providerId).toSet(), {53525, 53526});
    });

    test('a gone page is searched by its last title and replaced', () async {
      await addEntry('gone', 'Saved Name', malId: 5);
      final details = databases.details;
      await details
          .into(details.detail)
          .insert(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: 5,
              fetchedAt: 1,
              json: '{"id": 5, "title": "Old Title"}',
            ),
          );
      await details
          .into(details.gonePage)
          .insert(
            GonePageCompanion.insert(
              provider: 'mal',
              providerId: 5,
              checkedAt: 1,
            ),
          );
      searches['Old Title'] = [buildNode(9, 'Old Title')];

      expect(await buildMatching().matchEntry('gone'), MatchOutcome.linked);
      expect(await readMalId('gone'), 9);
    });

    test('a failed search leaves no trace', () async {
      await addEntry('hi', 'Hi-DRIVERS');
      searchStatus = 500;

      expect(await buildMatching().matchEntry('hi'), MatchOutcome.failed);
      expect(await hasAttempt('hi'), isFalse);
    });

    test('a user pick links in the screen lane', () async {
      await addEntry('bigo', 'THE Big O (2003)');
      await buildMatching().linkEntry('bigo', 567, lane: Lane.screen);

      expect(await readMalId('bigo'), 567);
      expect(asked, ['detail 567']);
      final record = databases.record;
      final entry = await (record.select(
        record.entry,
      )..where((row) => row.entryId.equals('bigo'))).getSingle();
      expect(entry.linkChangedAt, _now.millisecondsSinceEpoch);
    });

    test('runs not-linked entries due a search, in trickle order', () async {
      await addEntry('linked', 'Linked', malId: 1);
      await addEntry('planned', 'Planned Show', updatedAt: 5);
      await addEntry('watching', 'Watching Show', status: 'watching');
      await addEntry('tried lately', 'Tried Lately', status: 'watching');
      await addEntry('tried long ago', 'Tried Long Ago', status: 'dropped');
      final details = databases.details;
      for (final (entryId, days) in [
        ('tried lately', 10),
        ('tried long ago', 31),
      ]) {
        await details
            .into(details.matchAttempt)
            .insert(
              MatchAttemptCompanion.insert(
                entryId: entryId,
                searchedAt: _now
                    .subtract(Duration(days: days))
                    .millisecondsSinceEpoch,
              ),
            );
      }

      await buildMatching().run();

      expect(asked, ['Watching Show', 'Planned Show', 'Tried Long Ago']);
    });

    test('searches again by typo correction when MAL finds nothing', () async {
      final tree = TitleTree<String>()..add('frieren', ['Sousou no Frieren']);
      searches['sousou no frieren'] = [buildNode(52991, 'Sousou no Frieren')];

      final result = await buildMatching().searchPages(
        'Sousou no Frieran',
        tree,
      );

      expect(asked, ['Sousou no Frieran', 'sousou no frieren']);
      expect(result!.shownQuery, 'sousou no frieren');
      expect(result.isCorrected, isTrue);
      expect(result.results.single['id'], 52991);
    });
  });
}
