import 'dart:io';

import 'package:konsou/data/databases.dart';
import 'package:konsou/import/import_old_list.dart';

/// Imports the test list into the app's own data folder, so the Library shows
/// real rows. Close the app first and run from the repo root:
///   dart run tool/import_into_app.dart
/// It refuses when the app already has entries. The test list file is copied
/// before it is read, so it is never changed.
Future<void> main() async {
  final appData = Platform.environment['APPDATA'];
  if (appData == null) {
    stderr.writeln('APPDATA is not set');
    exitCode = 1;
    return;
  }
  final folder = Directory(
    '$appData${Platform.pathSeparator}com.konsou'
    '${Platform.pathSeparator}konsou',
  );
  final databases = await openDatabases(folder);
  try {
    final report = await importOldDatabase(
      File('testdata/konsou-test-list.db'),
      databases,
    );
    stdout.writeln(
      '${report.entries} entries, ${report.completions} finished '
      'watches, ${report.alerts} alerts imported into ${folder.path}',
    );
  } finally {
    await databases.close();
  }
}
