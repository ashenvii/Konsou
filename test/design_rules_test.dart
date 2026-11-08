import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colors, radii, font sizes and layout sizes may only be written in the
/// tokens file. The gallery is a dev screen with demo layout numbers, so it is
/// exempt from the size rule only.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !_norm(f.path).endsWith('design/tokens.dart'));

  // A size of 0 or 1 is not a design size (no gap, hairline, line height).
  const param =
      r'(width|height|dimension|size|strokeWidth|minWidth|maxWidth|minHeight|maxHeight)\s*:\s*(?!(0|1)\b)\d';
  const inset =
      r'EdgeInsets\.[^;]*?\b(horizontal|vertical|left|top|right|bottom)\s*:\s*(?!0\b)\d';
  const insetAll = r'EdgeInsets\.(all|only|symmetric|fromLTRB)\(\s*(?!0\b)\d';

  final rules = <String, (RegExp, bool Function(String path))>{
    'color literal': (RegExp(r'Color\(0x'), (_) => true),
    'named color': (RegExp(r'Colors\.'), (_) => true),
    'radius': (
      RegExp(r'BorderRadius\.(circular|all|only|vertical|horizontal)'),
      (_) => true,
    ),
    'font size number': (RegExp(r'fontSize:\s*\d'), (_) => true),
    'Size number': (
      RegExp(r'\bSize(\.square)?\(\s*(?!(0|1)\b)\d'),
      // The window's own start and minimum size are not design tokens.
      (path) => !_norm(path).endsWith('shell/window_config.dart'),
    ),
    'layout size number': (
      RegExp('$param|$inset|$insetAll'),
      (path) => !_norm(path).contains('lib/gallery/'),
    ),
  };

  for (final entry in rules.entries) {
    test('no ${entry.key} outside the tokens file', () {
      final (pattern, applies) = entry.value;
      final hits = <String>[];
      for (final file in files.where((f) => applies(f.path))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (pattern.hasMatch(lines[i])) hits.add('${file.path}:${i + 1}');
        }
      }
      expect(hits, isEmpty);
    });
  }

  test('the size rule actually matches what it should', () {
    final size = RegExp('$param|$inset|$insetAll');
    expect(size.hasMatch('SizedBox(width: 24)'), isTrue);
    expect(size.hasMatch('padding: const EdgeInsets.all(12)'), isTrue);
    expect(size.hasMatch('EdgeInsets.symmetric(horizontal: 4)'), isTrue);
    expect(size.hasMatch('strokeWidth: 3'), isTrue);
    expect(size.hasMatch('BoxConstraints(minWidth: 120)'), isTrue);
    expect(size.hasMatch('maxHeight: 48,'), isTrue);
    expect(
      RegExp(r'\bSize(\.square)?\(\s*(?!(0|1)\b)\d').hasMatch('Size(300, 200)'),
      isTrue,
    );
    expect(
      RegExp(r'\bSize(\.square)?\(\s*(?!(0|1)\b)\d')
          .hasMatch('Size.square(Tokens.x)'),
      isFalse,
    );
    expect(size.hasMatch('minWidth: Tokens.badgeSize,'), isFalse);
    expect(size.hasMatch('SizedBox(width: Tokens.railWidth)'), isFalse);
    expect(size.hasMatch('height: 1,'), isFalse);
    expect(size.hasMatch('EdgeInsets.all(Tokens.space4)'), isFalse);
  });
}

String _norm(String path) => path.replaceAll('\\', '/');
