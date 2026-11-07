/// Finds blocks of code that appear more than once. Two places count as a
/// duplicate when [window] meaningful lines in a row are the same. Blank
/// lines, comments, imports and lines that only close a bracket are ignored,
/// so formatting changes do not hide a copy.
library;

class Duplicate {
  const Duplicate(this.places, this.lines);

  /// "file:line" for every place the block appears.
  final List<String> places;
  final int lines;

  @override
  String toString() => '$lines+ lines repeated at ${places.join(', ')}';
}

class _Line {
  const _Line(this.number, this.text);
  final int number;
  final String text;
}

final _closingOnly = RegExp(r'^[\)\]\},;\s]+$');

List<_Line> _meaningful(String source) {
  final out = <_Line>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final text = lines[i].trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty ||
        text.startsWith('//') ||
        text.startsWith('import ') ||
        text.startsWith('export ') ||
        text.startsWith('part ') ||
        _closingOnly.hasMatch(text)) {
      continue;
    }
    out.add(_Line(i + 1, text));
  }
  return out;
}

/// [sources] maps a file name to its text.
List<Duplicate> findDuplicates(Map<String, String> sources, {int window = 6}) {
  final files = sources.keys.toList()..sort();
  final lines = {for (final f in files) f: _meaningful(sources[f]!)};

  // Where each run of [window] lines starts, as (file, index in that file).
  final starts = <String, List<(String, int)>>{};
  for (final f in files) {
    final l = lines[f]!;
    for (var i = 0; i + window <= l.length; i++) {
      final key = l.sublist(i, i + window).map((x) => x.text).join('\n');
      starts.putIfAbsent(key, () => []).add((f, i));
    }
  }

  final covered = <String, Set<int>>{for (final f in files) f: <int>{}};
  final found = <Duplicate>[];
  for (final f in files) {
    final l = lines[f]!;
    for (var i = 0; i + window <= l.length; i++) {
      if (covered[f]!.contains(i)) continue;
      final key = l.sublist(i, i + window).map((x) => x.text).join('\n');
      // Drop places that overlap an earlier one in the same file, so a
      // repeating pattern is not counted against itself.
      final places = <(String, int)>[];
      for (final p in starts[key]!) {
        final clash = places.any((q) => q.$1 == p.$1 && p.$2 < q.$2 + window);
        if (!clash) places.add(p);
      }
      if (places.length < 2 || places.first != (f, i)) continue;
      for (final (pf, pi) in places) {
        for (var k = 0; k < window; k++) {
          covered[pf]!.add(pi + k);
        }
      }
      found.add(
        Duplicate([
          for (final (pf, pi) in places) '$pf:${lines[pf]![pi].number}',
        ], window),
      );
    }
  }
  return found;
}
