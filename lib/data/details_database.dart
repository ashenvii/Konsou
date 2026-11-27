import 'package:drift/drift.dart';

part 'details_database.g.dart';

@DriftDatabase(include: {'details.drift'})
class DetailsDatabase extends _$DetailsDatabase {
  DetailsDatabase(super.executor);

  // details.db is safe to delete, so an upgrade only adds what is new
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(cover);
      if (from < 3) await _fixCoverColumns(migrator);
      if (from < 4) {
        await _addMissingColumn(
          'mal_score',
          "REAL GENERATED ALWAYS AS (json_extract(json, '\$.mean')) VIRTUAL",
        );
      }
      // the scan times checks by what it knows of a franchise, not a streak
      if (from < 5 &&
          (await _readColumns('scan_schedule')).contains('quiet_streak')) {
        await customStatement(
          'ALTER TABLE scan_schedule DROP COLUMN quiet_streak',
        );
      }
    },
  );

  // version 2 added the cover table but left detail with the old single
  // cover_url column, so a file made before it lacked the two new ones
  Future<void> _fixCoverColumns(Migrator migrator) async {
    if ((await _readDetailColumns()).isEmpty) {
      return migrator.createTable(detail);
    }
    await _addMissingColumn(
      'cover_medium_url',
      "TEXT GENERATED ALWAYS AS (json_extract(json, '\$.main_picture.medium')) "
          'VIRTUAL',
    );
    await _addMissingColumn(
      'cover_large_url',
      "TEXT GENERATED ALWAYS AS (json_extract(json, '\$.main_picture.large')) "
          'VIRTUAL',
    );
    if ((await _readDetailColumns()).contains('cover_url')) {
      await customStatement('ALTER TABLE detail DROP COLUMN cover_url');
    }
  }

  Future<Set<String>> _readDetailColumns() => _readColumns('detail');

  Future<Set<String>> _readColumns(String table) async => {
    for (final row in await customSelect(
      'SELECT name FROM pragma_table_xinfo(?)',
      variables: [Variable(table)],
    ).get())
      row.read<String>('name'),
  };

  // a table made by an earlier step of the same upgrade already has the column
  Future<void> _addMissingColumn(String name, String definition) async {
    if ((await _readDetailColumns()).contains(name)) return;
    await customStatement('ALTER TABLE detail ADD COLUMN $name $definition');
  }
}
