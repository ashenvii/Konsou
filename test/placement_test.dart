import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/shell/placement.dart';

void main() {
  // A 1920x1048 work area with a 32 pixel bar on top.
  const work = PixelRect(0, 32, 1920, 1080);

  test('a window fully on screen stays where it is', () {
    const want = PixelRect(231, 106, 1327, 806);
    expect(fitIntoWorkArea(want, work), want);
  });

  test('off to the top right slides in and keeps its size', () {
    const want = PixelRect(5000, -3000, 6096, -2300);
    final fitted = fitIntoWorkArea(want, work);
    expect(fitted.width, 1096);
    expect(fitted.height, 700);
    expect(fitted.right, work.right);
    expect(fitted.top, work.top);
  });

  test('off to the bottom left slides in and keeps its size', () {
    const want = PixelRect(-4000, 3000, -2904, 3700);
    final fitted = fitIntoWorkArea(want, work);
    expect(fitted.width, 1096);
    expect(fitted.height, 700);
    expect(fitted.left, work.left);
    expect(fitted.bottom, work.bottom);
  });

  test('a window larger than the work area shrinks to fit it', () {
    const want = PixelRect(100, 100, 2900, 1900);
    expect(fitIntoWorkArea(want, work), work);
  });

  test('a monitor to the left with negative coordinates works', () {
    const left = PixelRect(-1920, 0, 0, 1040);
    const want = PixelRect(-1900, 900, -800, 1600);
    final fitted = fitIntoWorkArea(want, left);
    expect(fitted.left, -1900);
    expect(fitted.bottom, left.bottom);
    expect(fitted.height, 700);
  });
}
