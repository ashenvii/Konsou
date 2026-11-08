import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:konsou/mal/detail_request.dart';
import 'package:konsou/mal/franchise_grouping.dart';
import 'package:konsou/mal/request_gate.dart';

import 'mal_client_id.dart';

const _seeds = {
  'danmachi': 28121,
  'monogatari': 5081,
  'fate': 10087,
  'steins_gate': 9253,
  'mushoku_tensei': 39535,
  'detective_conan': 235,
  'sword_art_online': 11757,
  'jojo': 14719,
  'kaguya_sama': 37999,
};

const _maxTitles = 40;
const _fields =
    'id,title,alternative_titles,media_type,status,start_date,num_episodes,'
    'related_anime';
// character and other relations are kept in the saved graph but not followed
const _followedRelations = {
  'sequel',
  'prequel',
  'side_story',
  'parent_story',
  'full_story',
  'summary',
  'spin_off',
  'alternative_version',
  'alternative_setting',
};

/// Walks MAL's related titles out from a few hard franchises and saves each
/// graph trimmed (ids, titles, types, dates, relations) for the franchise
/// tests. Run from the repo root with MAL_CLIENT_ID in .env, naming
/// franchises to fetch only those:
///   dart run tool/fetch_franchise_graphs.dart [danmachi monogatari ...]
Future<void> main(List<String> names) async {
  final clientId = readMalClientId();
  final gate = RequestGate();
  final client = http.Client();
  try {
    for (final MapEntry(key: name, value: seed) in _seeds.entries) {
      if (names.isNotEmpty && !names.contains(name)) continue;
      final titles = <int, Map<String, dynamic>>{};
      // story relations are walked first so the cap never cuts the story
      final story = Queue<int>()..add(seed);
      final side = Queue<int>();
      while ((story.isNotEmpty || side.isNotEmpty) &&
          titles.length < _maxTitles) {
        final id = story.isNotEmpty ? story.removeFirst() : side.removeFirst();
        if (titles.containsKey(id)) continue;
        final response = await gate.send(
          Lane.screen,
          () =>
              getDetail(client, clientId: clientId, malId: id, fields: _fields),
        );
        if (response.statusCode != 200) {
          stderr.writeln('$name: $id answered ${response.statusCode}');
          continue;
        }
        final title = _trim(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
        titles[id] = title;
        for (final relation in title['related'] as List<Map<String, dynamic>>) {
          final type = relation['relation_type'] as String;
          if (!_followedRelations.contains(type)) continue;
          (storyRelations.contains(type) ? story : side).add(
            relation['id'] as int,
          );
        }
      }
      File('test/mal/franchises/$name.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'seed': seed, 'titles': titles.values.toList()})}\n',
      );
      stdout.writeln('$name: ${titles.length} titles');
    }
  } finally {
    client.close();
  }
}

Map<String, dynamic> _trim(Map<String, dynamic> title) => {
  'id': title['id'],
  'title': title['title'],
  'title_english': (title['alternative_titles'] as Map?)?['en'],
  'media_type': title['media_type'],
  'status': title['status'],
  'start_date': title['start_date'],
  'num_episodes': title['num_episodes'],
  'related': [
    for (final relation in (title['related_anime'] as List? ?? []))
      {
        'id': relation['node']['id'],
        'title': relation['node']['title'],
        'relation_type': relation['relation_type'],
      },
  ],
};
