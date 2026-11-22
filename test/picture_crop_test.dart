import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/picture_crop.dart';

PictureLook look(int width, int height) => PictureLook(
  file: File('$width-$height.jpg'),
  width: width,
  height: height,
  rows: const [],
);

void main() {
  test('a busy band low down wins over a flat top', () {
    final rows = [for (var i = 0; i < 60; i++) i >= 40 ? 100.0 : 1.0];
    final at = cropAlignment(rows, const Size(400, 600), const Size(1200, 300));
    expect(at.y, greaterThan(0.5));
  });

  test('the same detail everywhere sits at the top', () {
    final rows = List.filled(60, 10.0);
    final at = cropAlignment(rows, const Size(400, 600), const Size(1200, 300));
    expect(at.y, -1);
  });

  test('a picture wider than its box is centred', () {
    final rows = [for (var i = 0; i < 30; i++) i * 1.0];
    expect(
      cropAlignment(rows, const Size(1600, 400), const Size(1200, 400)),
      Alignment.center,
    );
  });

  test('rows score detail, flat rows nothing', () {
    final flat = Uint8List(4 * 4 * 3)..fillRange(0, 48, 128);
    expect(rowDetail(flat, 4, 3), [0, 0]);
    final striped = Uint8List.fromList([
      for (var y = 0; y < 3; y++)
        for (var x = 0; x < 4; x++) ...[x.isEven ? 0 : 255, 0, 0, 255],
    ]);
    expect(rowDetail(striped, 4, 3).first, greaterThan(0));
  });

  test('the alternate is the widest picture that is wide enough', () {
    final small = look(320, 180);
    final tall = look(424, 600);
    final square = look(600, 600);
    expect(chooseAlternate([small, tall, square]), square);
    expect(chooseAlternate([small]), isNull);
    expect(chooseAlternate([]), isNull);
  });

  test("MAL's sizes of one picture are the same picture", () {
    const large = 'https://cdn.myanimelist.net/images/anime/1015/138006l.jpg';
    const medium = 'https://cdn.myanimelist.net/images/anime/1015/138006.jpg';
    const other = 'https://cdn.myanimelist.net/images/anime/1015/138007l.jpg';
    expect(sameMalPicture(large, medium), isTrue);
    expect(sameMalPicture(large, other), isFalse);
  });
}
