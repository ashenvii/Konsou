const _markedLetters = {
  'a': 'āáàâäãå',
  'c': 'ç',
  'e': 'ēéèêë',
  'i': 'īíìîï',
  'n': 'ñ',
  'o': 'ōóòôöõø',
  'u': 'ūúùûü',
  'y': 'ýÿ',
};

final Map<String, String> _plainLetters = {
  for (final MapEntry(key: plain, value: marked) in _markedLetters.entries)
    for (final letter in marked.split('')) letter: plain,
};

final _notLetterOrDigit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
final _japaneseOrChinese = RegExp(
  r'[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}]',
  unicode: true,
);

/// A title as the words search compares: lowercase, marks folded, split on
/// anything that is not a letter or digit.
List<String> foldWords(String title) {
  final folded = title
      .toLowerCase()
      .split('')
      .map((letter) => _plainLetters[letter] ?? letter)
      .join();
  return folded.split(_notLetterOrDigit).where((w) => w.isNotEmpty).toList();
}

bool isSameTitle(String a, String b) {
  final words = foldWords(a).join(' ');
  return words.isNotEmpty && words == foldWords(b).join(' ');
}

/// How many letters a typed word may have wrong: none for short words, more
/// for long ones, and none at all for Japanese or Chinese.
int getTypoAllowance(String word) {
  if (_japaneseOrChinese.hasMatch(word)) return 0;
  final length = word.runes.length;
  if (length <= 3) return 0;
  if (length <= 7) return 1;
  return 2;
}

/// The first row of the edit table for [typed]: an empty word is that many
/// letters away.
List<int> startTypoRow(List<int> typed) => [
  for (var i = 0; i <= typed.length; i++) i,
];

/// The next row of the edit table after one more letter of the stored word.
/// The last cell is how many letters [typed] is from the word so far.
List<int> stepTypoRow(List<int> previous, List<int> typed, int letter) {
  final row = List<int>.filled(previous.length, 0);
  row[0] = previous[0] + 1;
  for (var i = 1; i < row.length; i++) {
    final changed = previous[i - 1] + (typed[i - 1] == letter ? 0 : 1);
    final added = previous[i] + 1;
    final removed = row[i - 1] + 1;
    row[i] = [changed, added, removed].reduce((a, b) => a < b ? a : b);
  }
  return row;
}

/// Every title a provider page is known by: its main, English and Japanese
/// titles and its synonyms.
List<String> readProviderTitles(Map<String, dynamic> page) {
  final alternative = page['alternative_titles'] as Map? ?? const {};
  return [
    if (page['title'] case final String title) title,
    if (alternative['en'] case final String english when english.isNotEmpty)
      english,
    if (alternative['ja'] case final String japanese when japanese.isNotEmpty)
      japanese,
    for (final synonym in alternative['synonyms'] as List? ?? const [])
      synonym as String,
  ];
}
