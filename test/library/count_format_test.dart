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
}
