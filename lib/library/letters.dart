import '../search/title_words.dart';
import 'library_row.dart';

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
  final words = foldWords(name);
  if (words.isEmpty) return '#';
  final first = words.first[0].toUpperCase();
  return letterHeadings.contains(first) && first != '#' ? first : '#';
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
