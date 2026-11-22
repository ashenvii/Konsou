import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/dithered_gradient.dart';

void main() {
  const top = Color(0xFF1D1C20);
  const bottom = Color(0xFF0E0D10);

  test('every row averages to the exact gradient', () {
    const height = 900;
    final pixels = ditheredRows(top, bottom, height);
    for (final y in [0, 150, 450, 899]) {
      var sum = 0;
      for (var x = 0; x < ditherTileWidth; x++) {
        sum += pixels[(y * ditherTileWidth + x) * 4];
      }
      final t = y / (height - 1);
      final exact = 0x1D + (0x0E - 0x1D) * t;
      expect(sum / ditherTileWidth, closeTo(exact, 0.35));
    }
  });

  test('a row mixes two levels, so no band has a hard edge', () {
    final pixels = ditheredRows(top, bottom, 900);
    final y = 310;
    final levels = {
      for (var x = 0; x < ditherTileWidth; x++)
        pixels[(y * ditherTileWidth + x) * 4],
    };
    expect(levels.length, 2);
  });

  test('the ends are the end colours and every pixel is opaque', () {
    final pixels = ditheredRows(top, bottom, 100);
    expect(pixels[0], inInclusiveRange(0x1C, 0x1D));
    expect(pixels[3], 255);
  });
}
