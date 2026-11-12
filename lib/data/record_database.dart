import 'package:drift/drift.dart';

part 'record_database.g.dart';

@DriftDatabase(include: {'record.drift'})
class RecordDatabase extends _$RecordDatabase {
  RecordDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // 2: the alert type check gained earlier_unmarked
      if (from < 2) await migrator.alterTable(TableMigration(alert));
    },
  );
}
