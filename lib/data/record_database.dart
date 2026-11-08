import 'package:drift/drift.dart';

part 'record_database.g.dart';

@DriftDatabase(include: {'record.drift'})
class RecordDatabase extends _$RecordDatabase {
  RecordDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
