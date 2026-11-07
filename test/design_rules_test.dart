import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colors, radii and font sizes may only be written in the tokens file.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.replaceAll('\\', '/').endsWith('design/tokens.dart'));

  final rules = <String, RegExp>{
    'color literal': RegExp(r'Color\(0x'),
    'named color': RegExp(r'Colors\.'),
    'radius': RegExp(r'BorderRadius\.(circular|all|only|vertical|horizontal)'),
    'font size number': RegExp(r'fontSize:\s*\d'),
  };

  for (final entry in rules.entries) {
    test('no ${entry.key} outside the tokens file', () {
      final hits = <String>[];
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (entry.value.hasMatch(lines[i])) {
            hits.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(hits, isEmpty);
    });
  }
}
