import 'package:drift/drift.dart';

import '../data/databases.dart';
import 'title_index.dart';
import 'title_words.dart';
import 'title_tree.dart';

/// Search over the user's own entries, for the Library and Quick search.
/// Titles come from the typo-tolerant tree; notes are not searched.
class EntrySearch {
  EntrySearch(this._databases);

  final Databases _databases;
  TitleTree<TitleKey>? _tree;

  /// Rebuilds the tree from what is saved. Call after entries are added,
  /// renamed or linked.
  Future<void> refresh() async => _tree = await loadTitleTree(_databases);

  /// Entry ids matching [query], best first. Empty until the first refresh.
  List<String> findEntries(String query) => [
    for (final hit in _tree?.find(query) ?? const <TitleHit<TitleKey>>[])
      ?hit.key.entryId,
  ];

  /// What [typed] reads as after each word is corrected from the titles Konsou
  /// has seen, or null when that is what was typed or nothing can be told.
  String? correctedQuery(String typed) {
    final tree = _tree;
    if (tree == null) return null;
    final corrected = tree.correctQuery(typed);
    if (corrected.isEmpty || corrected == foldWords(typed).join(' ')) {
      return null;
    }
    return corrected;
  }

  /// The entries changed last, newest first.
  Future<List<String>> findRecent({int count = 5}) async {
    final rows = await _databases.record
        .customSelect(
          'SELECT entry_id FROM entry ORDER BY updated_at DESC, entry_id LIMIT ?',
          variables: [Variable.withInt(count)],
        )
        .get();
    return [for (final row in rows) row.read<String>('entry_id')];
  }

  /// [malIds] without the pages one of the user's entries already uses, so a
  /// MAL result never repeats a row from the list.
  Future<List<int>> dropListed(List<int> malIds) async {
    if (malIds.isEmpty) return [];
    final marks = malIds.map((_) => '?').join(',');
    final rows = await _databases.record
        .customSelect(
          "SELECT provider_id FROM entry_reference "
          "WHERE provider = 'mal' AND provider_id IN ($marks)",
          variables: [for (final id in malIds) Variable.withInt(id)],
        )
        .get();
    final listed = {for (final row in rows) row.read<int>('provider_id')};
    return [
      for (final id in malIds)
        if (!listed.contains(id)) id,
    ];
  }
}
