import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../library/entry_status.dart';

class FinishedWatch {
  const FinishedWatch({
    required this.watchNumber,
    required this.completedAt,
    required this.isEstimated,
  });

  // 0 is the first watch, 1 the first rewatch
  final int watchNumber;
  final int completedAt;
  final bool isEstimated;
}

class TitleEntry {
  const TitleEntry({
    required this.entryId,
    required this.status,
    required this.episodesWatched,
    required this.finishedWatches,
    this.name,
    this.malId,
    this.score,
    this.notes,
    this.startedAt,
  });

  final String entryId;
  final EntryStatus status;
  final int episodesWatched;

  final List<FinishedWatch> finishedWatches;

  final String? name;
  final int? malId;
  final int? score;
  final String? notes;
  final int? startedAt;

  bool get isNotLinked => malId == null;
}

Future<TitleEntry?> readEntry(Databases databases, String entryId) async {
  final record = databases.record;
  final entry = await (record.select(
    record.entry,
  )..where((row) => row.entryId.equals(entryId))).getSingleOrNull();
  if (entry == null) return null;
  final reference =
      await (record.select(record.entryReference)..where(
            (row) => row.entryId.equals(entryId) & row.provider.equals('mal'),
          ))
          .getSingleOrNull();
  final watches =
      await (record.select(record.completion)
            ..where((row) => row.entryId.equals(entryId))
            ..orderBy([(row) => OrderingTerm.asc(row.watchNumber)]))
          .get();
  return TitleEntry(
    entryId: entry.entryId,
    status: EntryStatus.parse(entry.status),
    episodesWatched: entry.episodesWatched,
    finishedWatches: [
      for (final watch in watches)
        FinishedWatch(
          watchNumber: watch.watchNumber,
          completedAt: watch.completedAt,
          isEstimated: watch.isEstimated,
        ),
    ],
    name: entry.name,
    malId: reference?.providerId,
    score: entry.score,
    notes: entry.notes,
    startedAt: entry.startedAt,
  );
}

// two entries can share one page: the one the user opened, else the newest
Future<TitleEntry?> readEntryOnPage(
  Databases databases,
  int malId, {
  String? preferred,
}) async {
  final rows = await databases.record
      .customSelect(
        '''
        SELECT entry.entry_id
        FROM entry JOIN entry_reference reference
          ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
        WHERE reference.provider_id = ?
        ORDER BY entry.entry_id = ? DESC, entry.updated_at DESC, entry.entry_id
        LIMIT 1
        ''',
        variables: [Variable.withInt(malId), Variable(preferred)],
      )
      .get();
  if (rows.isEmpty) return null;
  return readEntry(databases, rows.single.read<String>('entry_id'));
}
