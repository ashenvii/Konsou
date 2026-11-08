/// Checks that every token in lib/design/tokens.dart is listed, with the same
/// value, in the "Token index" section of notes/design/tokens.md, and the other
/// way round. The owner approves a token by adding it to that index.
library;

// The value may wrap over several lines, which `dart format` does for long
// ones, so it runs up to the semicolon.
final _declaration = RegExp(
  r'^\s*static const [\w<>]+ (\w+) =\s*([^;]+);',
  multiLine: true,
);

/// Token name to normalized value, read from the Dart source.
Map<String, String> readDartTokens(String source) {
  return {
    for (final m in _declaration.allMatches(source))
      m.group(1)!: _normalize(m.group(2)!),
  };
}

/// Token name to normalized value, read from the index in tokens.md. Null when
/// the file has no index section.
Map<String, String>? readIndex(String markdown) {
  final lines = markdown.split('\n').map((l) => l.trimRight()).toList();
  final start = lines.indexWhere((l) => l.trim() == '## Token index');
  if (start < 0) return null;
  final index = <String, String>{};
  for (final line in lines.skip(start + 1)) {
    if (line.startsWith('## ')) break;
    final m = RegExp(r'^- (\w+): (.+)$').firstMatch(line);
    if (m != null) index[m.group(1)!] = _normalize(m.group(2)!);
  }
  return index;
}

/// Everything that is out of step between the two. Empty means fine.
List<String> tokenProblems(String dartSource, String markdown) {
  final dart = readDartTokens(dartSource);
  final index = readIndex(markdown);
  if (index == null) {
    return ['tokens.md has no "## Token index" section'];
  }
  final problems = <String>[];
  for (final name in dart.keys) {
    if (!index.containsKey(name)) {
      problems.add('$name is in tokens.dart but not in tokens.md');
    } else if (index[name] != dart[name]) {
      problems.add(
        '$name is ${dart[name]} in tokens.dart but ${index[name]} in tokens.md',
      );
    }
  }
  for (final name in index.keys) {
    if (!dart.containsKey(name)) {
      problems.add('$name is in tokens.md but not in tokens.dart');
    }
  }
  return problems;
}

String _normalize(String value) {
  var v = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  // A fully opaque color is written as its six hex digits in tokens.md. Any
  // other alpha keeps all eight, so a change of alpha is a mismatch.
  final color = RegExp(
    r'^Color\(\s*0x([0-9A-Fa-f]{2})([0-9A-Fa-f]{6}),?\s*\)$',
  );
  final cm = color.firstMatch(v);
  if (cm != null) {
    final alpha = cm.group(1)!.toUpperCase();
    final rgb = cm.group(2)!.toUpperCase();
    return alpha == 'FF' ? rgb : '$alpha$rgb';
  }
  final hex = RegExp(r'^#?([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$').firstMatch(v);
  if (hex != null) return hex.group(1)!.toUpperCase();
  if (v.length >= 2 && (v.startsWith("'") || v.startsWith('"'))) {
    return v.substring(1, v.length - 1);
  }
  if (RegExp(r'^-?\d+\.0$').hasMatch(v)) v = v.substring(0, v.length - 2);
  return v;
}
