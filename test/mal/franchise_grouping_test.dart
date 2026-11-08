import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/mal/franchise_grouping.dart';

import '../support/franchise_graphs.dart';

List<FranchiseTitle> loadGraph(String name) => [
  for (final title in readGraphTitles(name))
    FranchiseTitle(
      id: title['id'] as int,
      mediaType: title['media_type'] as String?,
      startDate: title['start_date'] as String?,
      relations: [
        for (final relation in readRelations(title))
          TitleRelation(
            relation['id'] as int,
            relation['relation_type'] as String,
          ),
      ],
    ),
];

/// Each franchise as (story count, extra count), keyed by the title it is
/// named after.
Map<int, (int, int)> countCards(Map<int, FranchisePlace> places) {
  final cards = <int, (int, int)>{};
  for (final place in places.values) {
    final (story, extras) = cards[place.franchiseId] ?? (0, 0);
    cards[place.franchiseId] = place.isExtra
        ? (story, extras + 1)
        : (story + 1, extras);
  }
  return cards;
}

// worked out separately in Python from the rule in DECISIONS.md and approved
// by the owner as the expected cards
const _expected = <String, Map<int, (int, int)>>{
  // the 2016 OVA and Arrow of the Orion link into the story from one side
  // only, so they are extras
  'danmachi': {28121: (7, 6), 32887: (1, 0)},
  'detective_conan': {235: (1, 35), 6115: (2, 0), 1369: (1, 0), 8310: (1, 0)},
  'fate': {
    356: (10, 4),
    14829: (7, 7),
    55830: (3, 0),
    33047: (2, 0),
    34662: (1, 1),
    12565: (1, 0),
    34321: (1, 0),
    31389: (1, 0),
  },
  'jojo': {14719: (9, 2), 666: (2, 0), 3603: (1, 0), 41306: (1, 0)},
  'kaguya_sama': {37999: (6, 2)},
  'monogatari': {5081: (15, 6), 51068: (1, 0)},
  'mushoku_tensei': {39535: (7, 1)},
  'steins_gate': {
    9253: (3, 0),
    4975: (4, 0),
    30484: (2, 1),
    13599: (1, 0),
    32962: (1, 0),
  },
  'sword_art_online': {11757: (8, 4), 36475: (3, 1), 42916: (2, 0)},
};

Map<int, (int, bool)> placesAsRecords(Map<int, FranchisePlace> places) => {
  for (final MapEntry(key: malId, value: place) in places.entries)
    malId: (place.franchiseId, place.isExtra),
};

void main() {
  for (final MapEntry(key: name, value: expected) in _expected.entries) {
    group(name, () {
      test('groups into the expected franchises', () {
        expect(countCards(groupFranchises(loadGraph(name))), expected);
      });

      test('gives the same franchises from any order', () {
        final titles = loadGraph(name);
        final first = groupFranchises(titles);
        for (var seed = 1; seed <= 5; seed++) {
          final shuffled = [...titles]..shuffle(Random(seed));
          final again = groupFranchises(shuffled);
          expect(placesAsRecords(again), placesAsRecords(first));
        }
      });
    });
  }

  test('a crossover with parents in two franchises stands alone', () {
    final places = groupFranchises(loadGraph('detective_conan'));
    expect(places[1369]!.franchiseId, 1369);
    expect(places[1369]!.isExtra, isFalse);
  });

  test('an extra of an extra follows it into the franchise', () {
    final places = groupFranchises(loadGraph('detective_conan'));
    // Magic File 2 names both the TV series and Movie 12, itself an extra
    expect(places[5348]!.franchiseId, 235);
    expect(places[5348]!.isExtra, isTrue);
  });

  test('a title stays put whether or not a one-sided neighbour is fetched', () {
    final full = loadGraph('danmachi');
    final withoutOva = full.where((title) => title.id != 32801);
    for (final places in [groupFranchises(full), groupFranchises(withoutOva)]) {
      // Arrow of the Orion, which the 2016 OVA calls its prequel
      expect(places[37348]!.franchiseId, 28121);
      expect(places[37348]!.isExtra, isTrue);
    }
  });

  test('a TV series is never an extra', () {
    final places = groupFranchises(loadGraph('danmachi'));
    expect(places[32887]!.franchiseId, 32887);
  });
}
