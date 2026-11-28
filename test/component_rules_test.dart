import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// a call's arguments, allowing two levels of nested brackets
const _args = r'(?:[^()]|\((?:[^()]|\([^()]*\))*\))*?';

// the dev gallery shows each font as it is, so it writes raw styles
const _styles = {'lib/design/text_styles.dart', 'lib/gallery/'};

/// Looks a component already gives, which may only be written inside it.
/// Each rule names the files or folders allowed to hold the pattern.
final _rules = <String, (RegExp, Set<String>)>{
  'one line of text with an ellipsis, use OneLineText': (
    RegExp(
      '\\bText\\($_args'
      r'maxLines:\s*1,'
      '$_args'
      r'TextOverflow\.ellipsis',
    ),
    {'lib/components/one_line_text.dart'},
  ),
  'the lit lip under a well, use wellLip or sunkDisplay': (
    RegExp(r'BoxShadow\(\s*color:\s*Tokens\.edgeLight'),
    {'lib/components/sunk_decoration.dart'},
  ),
  'a TextPainter, use measureText': (
    RegExp(r'\bTextPainter\('),
    {'lib/components/measure_text.dart'},
  ),
  'a loading bar, use SkeletonLine or SkeletonLines': (
    RegExp(r'\bSkeleton\(\s*height:'),
    {'lib/components/skeleton_lines.dart'},
  ),
  'the page dim, use PageDim': (
    RegExp(r'Tokens\.dimAlpha'),
    {'lib/components/page_dim.dart'},
  ),
  'a font weight, use bold on AppText': (RegExp(r'\bFontWeight\.'), _styles),
  'a text size or tracking, use size on AppText': (
    RegExp(r'\b(fontSize|letterSpacing):'),
    // the app's default text style
    {..._styles, 'lib/main.dart'},
  ),
  'the wrapped line height, use .wrapped': (
    RegExp(r'height:\s*Tokens\.lineHeightWrapped'),
    _styles,
  ),
};

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

  for (final MapEntry(key: name, value: (pattern, homes)) in _rules.entries) {
    test('no $name', () {
      final hits = <String>[];
      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (homes.any(path.startsWith)) continue;
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
