import 'package:flutter_test/flutter_test.dart';

import '../../tool/tokens_check.dart';

const _dart = '''
abstract final class Tokens {
  static const Color ground = Color(0xFF080D10);
  static const BorderRadius square = BorderRadius.zero;
  static const double space1 = 4;
  static const double barHeight = 36;
  static const String sans = 'PlexSans';
}
''';

const _good = '''
# Tokens

## Other section
- ignored: 1

## Token index
- ground: 080D10
- square: BorderRadius.zero
- space1: 4
- barHeight: 36
- sans: PlexSans

## Questions
- also_ignored: 2
''';

void main() {
  test('reads colors, numbers, strings and radius from the Dart file', () {
    expect(readDartTokens(_dart), {
      'ground': '080D10',
      'square': 'BorderRadius.zero',
      'space1': '4',
      'barHeight': '36',
      'sans': 'PlexSans',
    });
  });

  test('matching files give no problems', () {
    expect(tokenProblems(_dart, _good), isEmpty);
  });

  test('a token missing from tokens.md is a problem', () {
    final md = _good.replaceAll('- space1: 4\n', '');
    expect(tokenProblems(_dart, md), [
      'space1 is in tokens.dart but not in tokens.md',
    ]);
  });

  test('an index entry with no token is a problem', () {
    final md = _good.replaceAll('## Questions', '- extra: 9\n\n## Questions');
    expect(tokenProblems(_dart, md), [
      'extra is in tokens.md but not in tokens.dart',
    ]);
  });

  test('a different value is a problem', () {
    final md = _good.replaceAll('barHeight: 36', 'barHeight: 40');
    expect(tokenProblems(_dart, md), hasLength(1));
  });

  test('a decimal and a whole number count as the same value', () {
    final dart = _dart.replaceAll('= 36;', '= 36.0;');
    expect(tokenProblems(dart, _good), isEmpty);
  });

  test('a declaration wrapped over two lines is still read', () {
    const wrapped = '''
abstract final class Tokens {
  static const Color ground =
      Color(0xFF080D10);
}
''';
    expect(readDartTokens(wrapped), {'ground': '080D10'});
  });

  test('a change of alpha is a problem', () {
    final dart = _dart.replaceAll('0xFF080D10', '0x80080D10');
    expect(tokenProblems(dart, _good), hasLength(1));
  });

  test('no index section is a problem', () {
    expect(tokenProblems(_dart, '# Tokens\n'), hasLength(1));
  });
}
