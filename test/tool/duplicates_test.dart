import 'package:flutter_test/flutter_test.dart';

import '../../tool/duplicates.dart';

String _block(String tag) =>
    '''
void $tag() {
  final a = compute(1);
  final b = compute(2);
  final c = compute(3);
  final d = compute(4);
  final e = compute(5);
  final f = compute(6);
  use(a, b, c, d, e, f);
}
''';

void main() {
  test('finds the same block in two files', () {
    final found = findDuplicates({
      'a.dart': 'import "x";\n${_block("one")}',
      'b.dart': '${_block("two")}\nvoid other() {}\n',
    });
    expect(found, hasLength(1));
    expect(found.first.places, hasLength(2));
    expect(found.first.places.first, startsWith('a.dart:'));
  });

  test('finds the same block twice in one file', () {
    final found = findDuplicates({
      'a.dart': '${_block("one")}\n${_block("two")}',
    });
    expect(found, hasLength(1));
  });

  test('different code is not a duplicate', () {
    final found = findDuplicates({
      'a.dart':
          'void a() {\n${List.generate(8, (i) => '  one$i();').join('\n')}\n}',
      'b.dart':
          'void b() {\n${List.generate(8, (i) => '  two$i();').join('\n')}\n}',
    });
    expect(found, isEmpty);
  });

  test('blank lines, comments and spacing do not hide a copy', () {
    final spaced = _block('one')
        .split('\n')
        .map((l) => l.isEmpty ? l : '      // note\n\n   $l')
        .join('\n');
    final found = findDuplicates({'a.dart': _block('one'), 'b.dart': spaced});
    expect(found, hasLength(1));
  });

  test('a short repeat under the window is fine', () {
    final found = findDuplicates({
      'a.dart': 'a();\nb();\nc();\n',
      'b.dart': 'a();\nb();\nc();\n',
    });
    expect(found, isEmpty);
  });

  test('a long run of one repeated line is reported once', () {
    final found = findDuplicates({
      'a.dart': List.generate(20, (_) => 'tick();').join('\n'),
    });
    expect(found, hasLength(1));
  });

  test('a run too short to repeat is not reported', () {
    final found = findDuplicates({
      'a.dart': List.generate(8, (_) => 'tick();').join('\n'),
    });
    expect(found, isEmpty);
  });
}
