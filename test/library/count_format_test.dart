import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/library/count_format.dart';

void main() {
  test('thousands are separated by commas', () {
    expect(formatCount(0), '0');
    expect(formatCount(999), '999');
    expect(formatCount(1000), '1,000');
    expect(formatCount(1236), '1,236');
    expect(formatCount(1234567), '1,234,567');
  });

  test('a counted word is plural for every count but one', () {
    expect(formatCountOf(1, 'title'), '1 title');
    expect(formatCountOf(0, 'title'), '0 titles');
    expect(formatCountOf(2, 'episode'), '2 episodes');
    expect(formatCountOf(1200, 'user'), '1,200 users');
  });
}
