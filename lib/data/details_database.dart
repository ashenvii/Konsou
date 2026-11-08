import 'package:drift/drift.dart';

part 'details_database.g.dart';

@DriftDatabase(include: {'details.drift'})
class DetailsDatabase extends _$DetailsDatabase {
  DetailsDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
