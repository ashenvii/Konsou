import 'package:drift/drift.dart';

part 'details_database.g.dart';

@DriftDatabase(include: {'details.drift'})
class DetailsDatabase extends _$DetailsDatabase {
  DetailsDatabase(super.executor);

  // details.db is safe to delete, so an upgrade only adds what is new
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(cover);
    },
  );
}
