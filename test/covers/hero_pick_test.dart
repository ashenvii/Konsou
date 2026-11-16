import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/covers/hero_pick.dart';

void main() {
  final pictures = [
    {'large': 'main.jpg'},
    {'large': 'a.jpg'},
    {'medium': 'b.jpg'},
  ];

  test('never picks the cover itself', () {
    for (var id = 0; id < 6; id++) {
      final url = pickHeroUrl(
        malId: id,
        pictures: pictures,
        mainLarge: 'main.jpg',
      );
      expect(url, isIn(['a.jpg', 'b.jpg']));
    }
  });

  test('a title keeps its picture and neighbours differ', () {
    String? pick(int id) =>
        pickHeroUrl(malId: id, pictures: pictures, mainLarge: 'main.jpg');
    expect(pick(7), pick(7));
    expect(pick(7), isNot(pick(8)));
  });

  test('no other picture means none', () {
    expect(
      pickHeroUrl(
        malId: 1,
        pictures: [
          {'large': 'main.jpg'},
        ],
        mainLarge: 'main.jpg',
      ),
      isNull,
    );
    expect(pickHeroUrl(malId: 1, pictures: null), isNull);
  });
}
