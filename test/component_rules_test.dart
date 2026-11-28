import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// a call's arguments, allowing two levels of nested brackets
const _args = r'(?:[^()]|\((?:[^()]|\([^()]*\))*\))*?';

/// Looks a component already gives, which may only be written inside it.
/// Each rule names the one file allowed to hold the pattern.
final _rules = <String, (RegExp, String)>{
  'one line of text with an ellipsis, use OneLineText': (
    RegExp(
      '\\bText\\($_args'
      r'maxLines:\s*1,'
      '$_args'
      r'TextOverflow\.ellipsis',
    ),
    'lib/components/one_line_text.dart',
  ),
  'the lit lip under a well, use wellLip or sunkDisplay': (
    RegExp(r'BoxShadow\(\s*color:\s*Tokens\.edgeLight'),
    'lib/components/sunk_decoration.dart',
  ),
  'a TextPainter, use measureText': (
    RegExp(r'\bTextPainter\('),
    'lib/components/measure_text.dart',
  ),
};

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

  for (final MapEntry(key: name, value: (pattern, home)) in _rules.entries) {
    test('no $name', () {
      final hits = <String>[];
      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (path == home) continue;
        final text = file.readAsStringSync();
        for (final match in pattern.allMatches(text)) {
          final line = '\n'.allMatches(text.substring(0, match.start)).length;
          hits.add('$path:${line + 1}');
        }
      }
      expect(hits, isEmpty);
    });
  }

  test('the rules match what they should', () {
    final oneLine = _rules.values.first.$1;
    expect(
      oneLine.hasMatch('''
Text(
  row.name,
  style: AppText.label(ink),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)'''),
      isTrue,
    );
    expect(
      oneLine.hasMatch(
        'Text(name, maxLines: 2, overflow: TextOverflow.ellipsis)',
      ),
      isFalse,
    );
    expect(
      oneLine.hasMatch(
        'OneLineText(name, maxLines: 1, overflow: TextOverflow.ellipsis)',
      ),
      isFalse,
    );
    expect(
      oneLine.hasMatch(
        "Text('a', maxLines: 1); Text('b', overflow: TextOverflow.ellipsis)",
      ),
      isFalse,
    );
  });
}
