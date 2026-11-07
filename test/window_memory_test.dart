import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/shell/window_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing saved gives null', () async {
    expect(await WindowMemory.load(), isNull);
  });

  test('save then load returns the same values', () async {
    const memory = WindowMemory(
      size: Size(1096, 700),
      position: Offset(231, 106),
      maximized: true,
    );
    await memory.save();
    final loaded = await WindowMemory.load();
    expect(loaded?.size, const Size(1096, 700));
    expect(loaded?.position, const Offset(231, 106));
    expect(loaded?.maximized, isTrue);
  });

  test('a partly saved state gives null', () async {
    SharedPreferences.setMockInitialValues({'window.width': 1000.0});
    expect(await WindowMemory.load(), isNull);
  });

  test('a zero or negative size is ignored', () async {
    SharedPreferences.setMockInitialValues({
      'window.width': 0.0,
      'window.height': -5.0,
      'window.x': 10.0,
      'window.y': 10.0,
    });
    expect(await WindowMemory.load(), isNull);
  });
}
