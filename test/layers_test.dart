import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Which folder under lib/ may import which. The data side (database, import,
/// MAL, search, sync, net) never touches Flutter or anything drawn, so it can be tested
/// without a screen and moved without a rewrite. Folders that do not exist yet
/// are simply not checked.
const _mayImport = <String, Set<String>>{
  'design': {'design'},
  'icons': {'icons', 'design'},
  'components': {'components', 'design', 'icons', 'library'},
  'shell': {'shell', 'design', 'components', 'icons'},
  'library': {'library', 'data', 'search'},
  'data': {'data'},
  'import': {'import', 'data'},
  'search': {'search', 'data'},
  'net': {'net'},
  'mal': {'mal', 'data', 'search', 'net'},
  'detail': {'detail', 'library', 'mal', 'data'},
  'sync': {'sync', 'data', 'import', 'net'},
  'screens': {
    'screens',
    'app',
    'design',
    'components',
    'icons',
    'library',
    'detail',
    'data',
    'import',
    'mal',
    'search',
    'sync',
    'net',
  },
};

/// Folders on the data side, which may not import any Flutter package.
const _dataSide = {
  'data',
  'import',
  'mal',
  'search',
  'sync',
  'net',
  'library',
  'detail',
};

/// Whatever is not in a folder above (main.dart, gallery) is wiring and may
/// import anything.
void main() {
  final root = Directory('lib');

  test('every folder keeps to its import rule', () {
    final problems = <String>[];
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final rel = file.path.replaceAll('\\', '/').split('lib/').last;
      final parts = rel.split('/');
      if (parts.length < 2) continue;
      final folder = parts.first;
      final allowed = _mayImport[folder];
      if (allowed == null) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final m = RegExp(r'''^import\s+['"]([^'"]+)['"]''')
            .firstMatch(lines[i]);
        if (m == null) continue;
        final target = m.group(1)!;
        if (_dataSide.contains(folder) &&
            target.startsWith('package:flutter')) {
          problems.add('${file.path}:${i + 1} imports $target');
        }
        if (target.startsWith('package:konsou/')) {
          problems.add('${file.path}:${i + 1} use a relative import');
        }
        if (!target.startsWith('.')) continue;
        final resolved = Uri.parse(rel).resolve(target).path;
        final other = resolved.split('/').first;
        if (other.endsWith('.dart')) {
          // A file straight in lib/, such as main.dart.
          problems.add('${file.path}:${i + 1} imports lib/$other');
        } else if (!allowed.contains(other)) {
          problems.add('${file.path}:${i + 1} $folder may not import $other');
        }
      }
    }
    expect(problems, isEmpty);
  });
}
