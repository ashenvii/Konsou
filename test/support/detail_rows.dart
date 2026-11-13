import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:konsou/data/databases.dart';
import 'package:konsou/data/details_database.dart';
import 'package:konsou/data/record_database.dart';

/// Saves one title's details the way a fetch would, with only the fields the
/// detail tests read.
Future<void> addTitle(
  Databases databases,
  int malId,
  String? start, {
  String type = 'tv',
  String airing = 'finished_airing',
  int episodes = 12,
  String? english,
  List<Map<String, Object?>> relations = const [],
  bool full = false,
  int fetchedAt = 1,
}) => databases.details
    .into(databases.details.detail)
    .insert(
      DetailCompanion.insert(
        provider: 'mal',
        providerId: malId,
        fetchedAt: fetchedAt,
        isFull: Value(full),
        json: jsonEncode({
          'id': malId,
          'title': 'Title $malId',
          'alternative_titles': {'en': english ?? '', 'ja': ''},
          'media_type': type,
          'start_date': start,
          'status': airing,
          'num_episodes': episodes,
          'related_anime': relations,
        }),
      ),
    );

/// A relation as MAL lists it. [node] adds what the short field list carries
/// about the other title.
Map<String, Object?> relate(
  int malId,
  String type, {
  Map<String, Object?> node = const {},
}) => {
  'node': {'id': malId, ...node},
  'relation_type': type,
};

Future<void> addEntry(
  Databases databases,
  String entryId, {
  int? malId,
  String status = 'plan_to_watch',
  int watched = 0,
  String? name,
  int changedAt = 5,
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
          progressChangedAt: changedAt,
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
