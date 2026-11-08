import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';
import 'package:konsou/search/title_index.dart';

void main() {
  late Directory folder;
  late Databases databases;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('konsou_title_index_test');
    databases = await openDatabases(folder);
  });

  tearDown(() async {
    await databases.close();
    folder.deleteSync(recursive: true);
  });

  test('entries, fetched details and suggestions are all searchable', () async {
    final record = databases.record;
    final details = databases.details;
    for (final (entryId, name) in [
      ('frieren', 'Frieren'),
      ('no page', 'Rick and Morty'),
    ]) {
      await record
          .into(record.entry)
          .insert(
            EntryCompanion.insert(
              entryId: entryId,
              name: Value(name),
              status: 'watching',
              addedAt: 1,
              progressChangedAt: 1,
            ),
          );
    }
    await record
        .into(record.entryReference)
        .insert(
          EntryReferenceCompanion.insert(
            entryId: 'frieren',
            provider: 'mal',
            providerId: 52991,
          ),
        );
    for (final (malId, json) in [
      (
        52991,
        '{"title": "Sousou no Frieren", "alternative_titles": {"en": "Frieren: Beyond Journey\'s End", "synonyms": []}}',
      ),
      (56885, '{"title": "Sousou no Frieren 2nd Season"}'),
    ]) {
      await details
          .into(details.detail)
          .insert(
            DetailCompanion.insert(
              provider: 'mal',
              providerId: malId,
              fetchedAt: 1,
              json: json,
            ),
          );
    }
    for (final entryId in ['no page', 'frieren']) {
      await details
          .into(details.matchSuggestion)
          .insert(
            MatchSuggestionCompanion.insert(
              entryId: entryId,
              provider: 'mal',
              providerId: 58000,
              position: 0,
              json: '{"title": "Rick and Morty: The Anime", "alternative_titles": {"synonyms": ["Rick and Morty Anime"]}}',
              foundAt: 1,
            ),
          );
    }

    final tree = await loadTitleTree(databases);

    expect(
      [for (final hit in tree.find('sousou frieren')) hit.key],
      [(entryId: 'frieren', malId: null), (entryId: null, malId: 56885)],
    );
    expect(
      [for (final hit in tree.find('journey')) hit.key],
      [(entryId: 'frieren', malId: null)],
    );
    expect(
      [for (final hit in tree.find('rick morty anime')) hit.key],
      [(entryId: 'no page', malId: null), (entryId: null, malId: 58000)],
    );
  });
}
