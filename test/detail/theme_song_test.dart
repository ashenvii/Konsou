import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/detail/theme_song.dart';

void main() {
  test('a full line splits into its parts', () {
    final song = ThemeSong.parse(
      '#01: "Morning Road (朝の道)" by Paper Lanterns (ペーパーランタンズ) (eps 1-12, 24)',
      place: 1,
    );
    expect(song.number, '1');
    expect(song.name, 'Morning Road');
    expect(song.nativeName, '朝の道');
    expect(song.artist, 'Paper Lanterns');
    expect(song.episodes, 'eps 1-12, 24');
  });

  test('a special keeps its letter, a Latin bracket stays in the name', () {
    final song = ThemeSong.parse(
      'S1: "Last Light (Acoustic)" by Mira (ep 13)',
      place: 3,
    );
    expect(song.number, 'S1');
    expect(song.name, 'Last Light (Acoustic)');
    expect(song.nativeName, isNull);
    expect(song.episodes, 'ep 13');
  });

  test('no number and no episodes still reads', () {
    final song = ThemeSong.parse('"Small Hours" by Mira', place: 2);
    expect(song.number, '2');
    expect(song.name, 'Small Hours');
    expect(song.artist, 'Mira');
    expect(song.episodes, isNull);
  });

  test('a line in another shape keeps its whole text', () {
    final song = ThemeSong.parse('Something else entirely', place: 4);
    expect(song.number, '4');
    expect(song.name, 'Something else entirely');
    expect(song.artist, isNull);
  });
}
