import 'package:flutter_test/flutter_test.dart';

import '../../tool/code_map.dart';

const _purposes = {
  'lib/components': 'Shared widgets.',
  'lib/screens': 'Screens.',
};

const _badge = '''
import 'package:flutter/widgets.dart';

/// A small count beside a label.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.quiet = false});

  final int count;
  final bool quiet;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

const _screen = '''
import 'package:flutter/widgets.dart';

import '../components/count_badge.dart';

/// The screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const CountBadge(3);
}
''';

CodeMap _build(
  Map<String, String> lib, {
  Map<String, String> tests = const {},
}) => buildCodeMap(lib, tests, purposes: _purposes);

void main() {
  test('lists a widget with its line, what it takes and where it is used', () {
    final map = _build(
      {
        'lib/components/count_badge.dart': _badge,
        'lib/screens/home_screen.dart': _screen,
      },
      tests: {
        'test/components/count_badge_test.dart':
            "import 'package:konsou/components/count_badge.dart';\n"
            'void main() { CountBadge(1); }\n',
      },
    );
    expect(map.problems, isEmpty);
    expect(
      map.markdown,
      contains(
        '- **CountBadge** (widget, line 4): A small count beside a label.\n'
        '  - takes `CountBadge(int count, {bool quiet = false})`\n'
        '  - used in: screens/home_screen.dart\n'
        '  - tests: components/count_badge_test.dart\n',
      ),
    );
  });

  test('fails a public thing with no /// line', () {
    final map = _build({
      'lib/components/count_badge.dart': 'class CountBadge {}\n',
      'lib/screens/home_screen.dart': '/// The screen.\nclass HomeScreen {}\n',
    });
    expect(map.problems, [
      'lib/components/count_badge.dart:1 CountBadge has no /// line',
    ]);
  });

  test('fails two public things with one name', () {
    final map = _build({
      'lib/components/count_badge.dart': '/// One.\nclass Badge {}\n',
      'lib/screens/home_screen.dart': '/// Two.\nclass Badge {}\n',
    });
    expect(map.problems.single, startsWith('Badge is declared 2 times'));
  });

  test('a name counts only where its file is imported', () {
    final map = _build({
      'lib/components/count_badge.dart':
          '/// A row of data.\ntypedef Row = Map;\n',
      'lib/screens/home_screen.dart':
          "import 'package:flutter/widgets.dart';\n"
          '/// The screen.\nWidget home() => Row();\n',
    });
    expect(
      map.markdown,
      contains(
        '- **Row** (typedef, line 2): A row of data.\n'
        '  - used in: nothing else\n',
      ),
    );
  });

  test('a use through a file that exports it counts', () {
    final map = _build({
      'lib/components/count_badge.dart': '/// A lane.\nenum Lane { screen }\n',
      'lib/components/providers.dart': "export 'count_badge.dart' show Lane;\n",
      'lib/screens/home_screen.dart':
          "import '../components/providers.dart';\n"
          '/// The lane.\nconst lane = Lane.screen;\n',
    });
    expect(map.markdown, contains('  - used in: screens/home_screen.dart\n'));
  });

  test('a riverpod provider is found by its generated name', () {
    final map = _build({
      'lib/components/count_badge.dart':
          '/// Rows.\n@riverpod\nList<int> libraryRows(Ref ref) => [];\n',
      'lib/screens/home_screen.dart':
          "import '../components/count_badge.dart';\n"
          '/// Reads.\nvoid read(ref) => ref.watch(libraryRowsProvider);\n',
    });
    expect(
      map.markdown,
      contains(
        '- **libraryRows** (provider, line 3): Rows.\n'
        '  - read as `libraryRowsProvider`\n',
      ),
    );
    expect(map.markdown, contains('  - used in: screens/home_screen.dart\n'));
  });

  test('fails a folder with no purpose and a purpose with no folder', () {
    final map = buildCodeMap(
      {'lib/components/count_badge.dart': _badge},
      {},
      purposes: {'lib/gone': 'Gone.'},
    );
    expect(map.problems, [
      'lib/components has no line in folderPurposes in tool/code_map.dart',
      'lib/gone is in folderPurposes but has no Dart files',
    ]);
  });

  test('a screen tree opens each widget once', () {
    final map = _build({
      'lib/components/count_badge.dart': _badge,
      'lib/screens/home_screen.dart': _screen,
      'lib/app/routes.dart':
          "import '../screens/home_screen.dart';\n"
          "import '../components/count_badge.dart';\n"
          '/// Routes.\nfinal routes = [HomeScreen(), CountBadge(1)];\n',
    });
    expect(
      map.markdown,
      contains('```\nHomeScreen\n  CountBadge\nCountBadge (above)\n```'),
    );
  });
}
