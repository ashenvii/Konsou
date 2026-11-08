import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/data/generate_id.dart';

void main() {
  test('an id is 32 lowercase hex characters', () {
    expect(generateId(), matches(RegExp(r'^[0-9a-f]{32}$')));
  });

  test('ids do not repeat', () {
    final ids = {for (var i = 0; i < 10000; i++) generateId()};
    expect(ids, hasLength(10000));
  });
}
