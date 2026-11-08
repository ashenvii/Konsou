import 'package:drift/drift.dart' show Variable;

import '../data/record_database.dart';
import 'detail_request.dart';
import 'request_gate.dart';

/// How long a gone page is left alone before it is checked again.
const _goneRecheck = Duration(days: 30);

/// Fetches details in the background, one title at a time, for entries that
/// have none yet. It keeps no progress of its own: what still has no details
/// is what is left.
class Trickle {
  Trickle({
    required this.record,
    required this.detailRequest,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final RecordDatabase record;
  final DetailRequest detailRequest;
  final DateTime Function() _now;
  var _stopped = false;

  /// Runs until every entry has details or [stop] is called.
  Future<void> run() async {
    _stopped = false;
    // titles that failed this run, so one bad page cannot hold the trickle
    final failed = <int>{};
    while (!_stopped) {
      final malId = await _nextTitle(failed);
      if (malId == null) return;
      final outcome = await detailRequest.fetch(
        malId,
        lane: Lane.trickle,
        full: false,
      );
      if (outcome == FetchOutcome.failed) failed.add(malId);
    }
  }

  void stop() => _stopped = true;

  Future<int?> _nextTitle(Set<int> skip) async {
    final goneSince = _now().subtract(_goneRecheck).millisecondsSinceEpoch;
    final rows = await record
        .customSelect(
          '''
      SELECT entry_reference.provider_id
      FROM entry
      JOIN entry_reference ON entry_reference.entry_id = entry.entry_id
        AND entry_reference.provider = 'mal'
      LEFT JOIN details.detail ON detail.provider = 'mal'
        AND detail.provider_id = entry_reference.provider_id
      LEFT JOIN details.gone_page ON gone_page.provider = 'mal'
        AND gone_page.provider_id = entry_reference.provider_id
        AND gone_page.checked_at > ?
      WHERE detail.provider_id IS NULL AND gone_page.provider_id IS NULL
        AND entry_reference.provider_id NOT IN (${skip.join(', ')})
      ORDER BY CASE entry.status
          WHEN 'watching' THEN 0 WHEN 'rewatching' THEN 0
          WHEN 'plan_to_watch' THEN 1 WHEN 'on_hold' THEN 2
          WHEN 'completed' THEN 3 WHEN 'dropped' THEN 4 ELSE 5
        END, entry.updated_at DESC
      LIMIT 1
      ''',
          variables: [Variable.withInt(goneSince)],
        )
        .get();
    return rows.isEmpty ? null : rows.single.read<int>('provider_id');
  }
}
