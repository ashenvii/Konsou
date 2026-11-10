import 'package:drift/drift.dart';

part 'details_database.g.dart';

@DriftDatabase(include: {'details.drift'})
class DetailsDatabase extends _$DetailsDatabase {
  DetailsDatabase(super.executor);

  // details.db is safe to delete, so an upgrade only adds what is new
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(cover);
      if (from < 3) await _fixCoverColumns(migrator);
    },
  );

  // version 2 added the cover table but left detail with the old single
  // cover_url column, so a file made before it lacked the two new ones
  Future<void> _fixCoverColumns(Migrator migrator) async {
    final columns = await customSelect(
      "SELECT name FROM pragma_table_xinfo('detail')",
    ).get();
    if (columns.isEmpty) return migrator.createTable(detail);
    final names = columns.map((row) => row.read<String>('name')).toSet();
    if (!names.contains('cover_medium_url')) {
      await customStatement(
        'ALTER TABLE detail ADD COLUMN cover_medium_url TEXT '
        "GENERATED ALWAYS AS (json_extract(json, '\$.main_picture.medium')) "
        'VIRTUAL',
      );
    }
    if (!names.contains('cover_large_url')) {
      await customStatement(
        'ALTER TABLE detail ADD COLUMN cover_large_url TEXT '
        "GENERATED ALWAYS AS (json_extract(json, '\$.main_picture.large')) "
        'VIRTUAL',
      );
    }
    if (names.contains('cover_url')) {
      await customStatement('ALTER TABLE detail DROP COLUMN cover_url');
    }
  }
}
