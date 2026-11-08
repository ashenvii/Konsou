import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/search/title_words.dart';

void main() {
  test('folds case, punctuation and marked letters', () {
    expect(foldWords('Hi-DRIVERS!'), ['hi', 'drivers']);
    expect(foldWords('Shōnen Ōkami: Séance'), ['shonen', 'okami', 'seance']);
    expect(foldWords('Sousou no Frieren: ●● no Mahou Part 2'), [
      'sousou',
      'no',
      'frieren',
      'no',
      'mahou',
      'part',
      '2',
    ]);
    expect(foldWords('  '), isEmpty);
  });

  test('japanese and chinese stay whole between spaces and marks', () {
    expect(foldWords('葬送のフリーレン'), ['葬送のフリーレン']);
    expect(foldWords('劇場総集編 ぼっち・ざ・ろっく！'), ['劇場総集編', 'ぼっち', 'ざ', 'ろっく']);
  });

  test('typo allowance grows with the word', () {
    expect(getTypoAllowance('one'), 0);
    expect(getTypoAllowance('piece'), 1);
    expect(getTypoAllowance('kanketsu'), 2);
    expect(getTypoAllowance('葬送のフリーレン'), 0);
  });

  test('titles are equal when their folded words are', () {
    expect(isSameTitle('Hi-DRIVERS', 'Hi-DRIVERS!'), isTrue);
    expect(
      isSameTitle('Akane-banashi 2nd Season', 'Akane-banashi 2nd Season'),
      isTrue,
    );
    expect(isSameTitle('Bocchi the Rock!', 'Bocchi the Rock! Movie'), isFalse);
    expect(isSameTitle('', ''), isFalse);
  });
}
