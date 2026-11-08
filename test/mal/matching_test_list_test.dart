import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/import/import_old_list.dart';
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/matching.dart';
import 'package:konsou/mal/request_gate.dart';
import 'package:konsou/mal/search_request.dart';

import '../support/test_list.dart';

const _savedSearches = 'testdata/match-searches.json';

void main() {
  final skip = File(_savedSearches).existsSync()
      ? skipWithoutTestList
      : '$_savedSearches is missing; run tool/fetch_match_searches.dart';

  test('matching on the test list\'s not-linked entries', () async {
    final searches = jsonDecode(
      File(_savedSearches).readAsStringSync(),
    ) as Map<String, dynamic>;
    final folder = Directory.systemTemp.createTempSync('konsou_match_list');
    final databases = await openDatabases(folder);
    addTearDown(() async {
      await databases.close();
      folder.deleteSync(recursive: true);
    });
    await importOldDatabase(File(testListPath), databases);

    final client = MockClient((request) async {
      final query = request.url.queryParameters['q'];
      if (query == null) {
        return http.Response('{"id": ${request.url.pathSegments.last}}', 200);
      }
      final saved = searches[query];
      if (saved == null) return http.Response('not saved: $query', 500);
      return http.Response.bytes(utf8.encode(jsonEncode(saved)), 200);
    });
    final gate = RequestGate(wait: (_) async {});
    final detailRequest = DetailRequest(
      clientId: 'test-client',
      client: client,
      gate: gate,
      details: databases.details,
    );
    await Matching(
      databases: databases,
      searchRequest: SearchRequest(
        clientId: 'test-client',
        client: client,
        gate: gate,
      ),
      detailRequest: detailRequest,
    ).run();

    final rows = await databases.record.customSelect('''
      SELECT entry.name, reference.provider_id AS linked,
        (SELECT group_concat(provider_id) FROM (
          SELECT provider_id FROM details.match_suggestion
          WHERE match_suggestion.entry_id = entry.entry_id
          ORDER BY position)) AS suggested
      FROM entry
      LEFT JOIN entry_reference reference
        ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
      WHERE entry.entry_id NOT IN (
        SELECT entry_id FROM entry_reference WHERE provider = 'mal'
          AND provider_id NOT IN (SELECT provider_id FROM details.detail))
      ''').get();
    final linked = {
      for (final row in rows)
        row.read<String>('name'): ?row.read<int?>('linked'),
    };
    final suggested = {
      for (final row in rows)
        row.read<String>('name'): (row.read<String?>('suggested') ?? '')
            .split(',')
            .where((id) => id.isNotEmpty)
            .map(int.parse)
            .toList(),
    };

    expect(rows, hasLength(38));
    expect(linked, {
      'Akane-banashi 2nd Season': 64439,
      'Hi-DRIVERS': 53525,
      'Wu Liuqi Movie': 64583,
    });
    for (final name in [
      'Rick and Morty: The Anime',
      'Scott Pilgrim Takes Off',
      'Thunderbolt Fantasy: Sword Travels in the East',
      // small words and typos no longer let unrelated titles through
      'IRIS OUT',
      'The Lord of the Rings: The War of the Rohirrim',
    ]) {
      expect(suggested[name], isEmpty, reason: name);
    }
    // every season shares the english title, so none is linked
    expect(suggested['Fox Spirit Matchmaker'], contains(31499));
    expect(suggested['The Big O II']!.first, 567);
    expect(suggested['Koro-sensei Q!'], [34389]);
    expect(suggested['Genshin'], isNot(contains(45)));
    expect(suggested['Sousou no Frieren: ●● no Mahou Part 2']!.first, 56885);
  }, skip: skip);
}
