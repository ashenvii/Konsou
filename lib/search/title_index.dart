import 'dart:convert';

import '../data/databases.dart';
import 'title_tree.dart';
import 'title_words.dart';

/// What a title search hit points at: an entry on the list, or a provider page
/// Konsou has seen that is not on it.
typedef TitleKey = ({String? entryId, int? malId});

/// Builds the title search from every title Konsou has seen: entries by their
/// name and their details, then fetched details and suggestions not on the
/// list.
Future<TitleTree<TitleKey>> loadTitleTree(Databases databases) async {
  final rows = await databases.record.customSelect('''
    SELECT entry.entry_id, entry.name, NULL AS provider_id, detail.title,
      json_extract(detail.json, '\$.alternative_titles') AS alternative
    FROM entry
    LEFT JOIN entry_reference reference
      ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
    LEFT JOIN details.detail ON detail.provider = 'mal'
      AND detail.provider_id = reference.provider_id
    UNION ALL
    SELECT NULL, NULL, provider_id, title,
      json_extract(json, '\$.alternative_titles')
    FROM details.detail
    WHERE provider = 'mal' AND provider_id NOT IN (
      SELECT provider_id FROM entry_reference WHERE provider = 'mal')
    UNION ALL
    SELECT NULL, NULL, provider_id, json_extract(json, '\$.title'),
      json_extract(json, '\$.alternative_titles')
    FROM details.match_suggestion
    WHERE provider = 'mal'
      AND provider_id NOT IN (
        SELECT provider_id FROM details.detail WHERE provider = 'mal')
      AND provider_id NOT IN (
        SELECT provider_id FROM entry_reference WHERE provider = 'mal')
    GROUP BY provider_id
    ''').get();

  final tree = TitleTree<TitleKey>();
  for (final row in rows) {
    final entryId = row.read<String?>('entry_id');
    final alternative = row.read<String?>('alternative');
    final titles = [
      ?row.read<String?>('name'),
      ...readProviderTitles({
        'title': row.read<String?>('title'),
        'alternative_titles': alternative == null
            ? null
            : jsonDecode(alternative),
      }),
    ];
    tree.add(
      entryId != null
          ? (entryId: entryId, malId: null)
          : (entryId: null, malId: row.read<int>('provider_id')),
      titles,
      own: entryId != null,
    );
  }
  return tree;
}
