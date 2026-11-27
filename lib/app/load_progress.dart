import '../data/databases.dart';

enum LoadJob { details, covers }

typedef LoadCount = ({int done, int total});

/// What the background work is loading, for the wordmark. Nothing loading is
/// the plain `LoadProgress()`. The counts are read from the databases each
/// time, never kept, so a restart picks up where the list stands.
class LoadProgress {
  const LoadProgress({
    this.job,
    this.waiting = false,
    this.finished = false,
    this.details = (done: 0, total: 0),
    this.covers = (done: 0, total: 0),
  });

  final LoadJob? job;

  /// The job's gate is backing off: MAL or the picture server is not
  /// answering, and the work carries on by itself when it does.
  final bool waiting;

  /// Everything that was loading is in.
  final bool finished;

  final LoadCount details;
  final LoadCount covers;

  LoadCount? get current => switch (job) {
    LoadJob.details => details,
    LoadJob.covers => covers,
    null => null,
  };

  @override
  bool operator ==(Object other) =>
      other is LoadProgress &&
      other.job == job &&
      other.waiting == waiting &&
      other.finished == finished &&
      other.details == details &&
      other.covers == covers;

  @override
  int get hashCode => Object.hash(job, waiting, finished, details, covers);
}

/// Titles linked to MAL with details saved, and list covers saved for titles
/// whose details name one. A gone page has no details to load, so it is not
/// counted.
Future<({LoadCount details, LoadCount covers})> readLoadCounts(
  Databases databases,
) async {
  final row = await databases.record.customSelect('''
    WITH linked AS (
      SELECT DISTINCT reference.provider_id AS id
      FROM entry_reference reference
      JOIN entry ON entry.entry_id = reference.entry_id
      WHERE reference.provider = 'mal'
        AND reference.provider_id NOT IN (SELECT provider_id
          FROM details.gone_page WHERE provider = 'mal')
    )
    SELECT
      (SELECT COUNT(*) FROM linked) AS details_total,
      (SELECT COUNT(*) FROM linked JOIN details.detail detail
        ON detail.provider = 'mal' AND detail.provider_id = linked.id)
        AS details_done,
      (SELECT COUNT(*) FROM linked JOIN details.detail detail
        ON detail.provider = 'mal' AND detail.provider_id = linked.id
        WHERE detail.cover_medium_url IS NOT NULL
          AND detail.cover_medium_url <> '') AS covers_total,
      (SELECT COUNT(*) FROM linked JOIN details.detail detail
        ON detail.provider = 'mal' AND detail.provider_id = linked.id
        JOIN details.cover cover ON cover.provider = 'mal'
          AND cover.provider_id = linked.id AND cover.size = 'medium'
          AND cover.url = detail.cover_medium_url) AS covers_done
    ''').getSingle();
  return (
    details: (
      done: row.read<int>('details_done'),
      total: row.read<int>('details_total'),
    ),
    covers: (
      done: row.read<int>('covers_done'),
      total: row.read<int>('covers_total'),
    ),
  );
}
