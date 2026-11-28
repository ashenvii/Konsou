import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/measure_text.dart';

void main() {
  const style = TextStyle(fontSize: 10);

  test('a longer text is wider, and larger text is wider still', () {
    final short = measureText('ab', style, textScaler: TextScaler.noScaling);
    final long = measureText('abcd', style, textScaler: TextScaler.noScaling);
    final scaled = measureText(
      'abcd',
      style,
      textScaler: const TextScaler.linear(2),
    );
    expect(long.width, greaterThan(short.width));
    expect(scaled.width, greaterThan(long.width));
    expect(long.cut, isFalse);
  });

  test('a text past its lines in a narrow box is cut', () {
    final measured = measureText(
      'one two three four five six',
      style,
      textScaler: TextScaler.noScaling,
      maxLines: 2,
      maxWidth: 30,
    );
    expect(measured.cut, isTrue);
  });
}
