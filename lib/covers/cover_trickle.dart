import '../data/databases.dart';
import '../mal/request_gate.dart';
import '../net/drain_queue.dart';
import 'cover_size.dart';
import 'cover_store.dart';

/// Keeps the medium cover of every entry on the list, fetched in the
/// background once its details are in. Newest change first, so what the user
/// is working on comes before the old shelf.
class CoverTrickle {
  CoverTrickle({required this.databases, required this.store});

  final Databases databases;
  final CoverStore store;
  var _stopped = false;

  /// Runs until every entry has its cover, or [stop] is called, then trims the
  /// pool.
  Future<void> run() async {
    _stopped = false;
    await store.forgetMissingFiles();
    await drainQueue<int>(
      isStopped: () => _stopped,
      next: _nextTitle,
      // a failure or a title with no picture is left alone for this run
      work: (malId) async =>
          await store.fetchCover(malId, CoverSize.medium, lane: Lane.trickle) !=
          CoverOutcome.fetched,
    );
    await store.trimPool();
  }

  void stop() => _stopped = true;

  Future<int?> _nextTitle(Set<int> skip) async {
    final rows = await databases.record.customSelect('''
      SELECT reference.provider_id
      FROM entry
      JOIN entry_reference reference
        ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
      JOIN details.detail detail
        ON detail.provider = 'mal' AND detail.provider_id = reference.provider_id
      LEFT JOIN details.cover cover
        ON cover.provider = 'mal' AND cover.provider_id = detail.provider_id
        AND cover.size = 'medium'
      WHERE detail.cover_medium_url IS NOT NULL
        AND detail.cover_medium_url <> ''
        AND (cover.provider_id IS NULL OR cover.url <> detail.cover_medium_url)
        AND reference.provider_id NOT IN (${skip.join(', ')})
      GROUP BY reference.provider_id
      ORDER BY MAX(entry.updated_at) DESC, reference.provider_id
      LIMIT 1
      ''').get();
    return rows.isEmpty ? null : rows.single.read<int>('provider_id');
  }
}
