import 'package:drift/drift.dart';

import '../data/record_database.dart';
import 'franchise_grouping.dart';

/// A saved title as the franchise grouping reads it, with MAL's airing status.
class SavedTitle {
  SavedTitle(this.title, this.airingStatus);

  final FranchiseTitle title;
  final String? airingStatus;
}

/// Saved titles with their relations, all of them or only [malId]. The record
/// connection has details.db attached.
Future<Map<int, SavedTitle>> readSavedTitles(
  RecordDatabase record, {
  int? malId,
}) async {
  final rows = await record
      .customSelect(
        '''
      SELECT detail.provider_id, detail.media_type, detail.start_date,
             detail.airing_status,
             json_extract(relation.value, '\$.node.id') AS relation_id,
             json_extract(relation.value, '\$.relation_type') AS relation_type
      FROM details.detail
      LEFT JOIN json_each(detail.json, '\$.related_anime') AS relation
      WHERE detail.provider = 'mal' AND (? IS NULL OR detail.provider_id = ?)
      ''',
        variables: [Variable(malId), Variable(malId)],
      )
      .get();
  final titles = <int, SavedTitle>{};
  for (final row in rows) {
    final id = row.read<int>('provider_id');
    final saved = titles.putIfAbsent(
      id,
      () => SavedTitle(
        FranchiseTitle(
          id: id,
          mediaType: row.readNullable<String>('media_type'),
          startDate: row.readNullable<String>('start_date'),
          relations: [],
        ),
        row.readNullable<String>('airing_status'),
      ),
    );
    final relationId = row.readNullable<int>('relation_id');
    final relationType = row.readNullable<String>('relation_type');
    if (relationId != null && relationType != null) {
      saved.title.relations.add(TitleRelation(relationId, relationType));
    }
  }
  return titles;
}
