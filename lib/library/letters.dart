import 'library_row.dart';
import 'library_view.dart';

const letterHeadings = [
  '#',
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

/// What a screen reader says for a heading.
String letterLabel(String letter) =>
    letter == '#' ? 'Numbers and symbols' : letter;

String letterOf(String name) {
  final folded = foldTitle(name);
  if (folded.isEmpty) return '#';
  final first = folded[0].toUpperCase();
  return letterHeadings.contains(first) ? first : '#';
}

List<({String letter, List<LibraryRow> rows})> groupByLetter(
  List<LibraryRow> rows,
) {
  final byLetter = <String, List<LibraryRow>>{};
  for (final row in rows) {
    byLetter.putIfAbsent(letterOf(row.name), () => []).add(row);
  }
  return [
    for (final letter in letterHeadings)
      if (byLetter.containsKey(letter))
        (letter: letter, rows: byLetter[letter]!),
  ];
}
