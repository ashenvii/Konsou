import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// A picture on disk with what it takes to crop it well: its size and how
/// much detail each row has, read once from a small copy.
class PictureLook {
  const PictureLook({
    required this.file,
    required this.width,
    required this.height,
    required this.rows,
  });

  final File file;
  final int width;
  final int height;

  /// Detail per row, top to bottom, of a [sampleWidth] wide copy.
  final List<double> rows;

  /// How wide the copy is that the rows are read from.
  static const sampleWidth = 48;

  /// Reads [file]'s size and rows. Null when it is not a picture.
  static Future<PictureLook?> read(File file) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;
      codec = await descriptor.instantiateCodec(targetWidth: sampleWidth);
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData();
      if (data == null) return null;
      return PictureLook(
        file: file,
        width: width,
        height: height,
        rows: rowDetail(data.buffer.asUint8List(), image.width, image.height),
      );
    } on Exception {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}

/// How much each row of an RGBA picture changes, across and down: busy rows
/// (faces, lettering) score high, flat sky and fills low.
List<double> rowDetail(Uint8List rgba, int width, int height) {
  double light(int x, int y) {
    final i = (y * width + x) * 4;
    return 0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2];
  }

  return [
    for (var y = 0; y < height - 1; y++)
      () {
        var sum = 0.0;
        for (var x = 0; x < width - 1; x++) {
          final here = light(x, y);
          sum +=
              (light(x + 1, y) - here).abs() + (light(x, y + 1) - here).abs();
        }
        return sum;
      }(),
  ];
}

// a band lower down must have this much more detail to win over one at the
// top, where faces and titles usually are
const _topLean = 0.35;

/// Where a picture of [picture] size sits in a [box] it covers: the band
/// with the most detail, leaning toward the top. Centred when the picture is
/// wider than the box, since then it is cropped at the sides instead.
Alignment cropAlignment(List<double> rows, Size picture, Size box) {
  if (rows.isEmpty || picture.isEmpty || box.isEmpty) return Alignment.center;
  final drawnHeight = box.width * picture.height / picture.width;
  final share = box.height / drawnHeight;
  if (share >= 1) return Alignment.center;
  final window = (share * rows.length).round().clamp(1, rows.length);
  var best = 0;
  var bestScore = double.negativeInfinity;
  var sum = 0.0;
  for (var i = 0; i < rows.length; i++) {
    sum += rows[i];
    if (i >= window) sum -= rows[i - window];
    if (i < window - 1) continue;
    final start = i - window + 1;
    final score = sum * (1 - _topLean * start / rows.length);
    if (score > bestScore) {
      bestScore = score;
      best = start;
    }
  }
  final room = rows.length - window;
  if (room <= 0) return Alignment.center;
  return Alignment(0, best / room * 2 - 1);
}

/// The picture to show behind a title instead of its cover: the widest of
/// MAL's extra pictures that is at least [minWidth] pixels wide and is not the
/// cover itself, which MAL lists among them. Null when there is none.
PictureLook? chooseAlternate(
  Iterable<PictureLook> looks, {
  int minWidth = 400,
}) {
  PictureLook? best;
  for (final look in looks) {
    if (look.width < minWidth) continue;
    if (best == null || look.width / look.height > best.width / best.height) {
      best = look;
    }
  }
  return best;
}

/// Whether two of MAL's picture addresses are the same picture, whatever
/// size: ".../138006l.jpg" and ".../138006.jpg" are.
bool sameMalPicture(String a, String b) => _stem(a) == _stem(b);

String _stem(String url) {
  final path = Uri.tryParse(url)?.path ?? url;
  final dot = path.lastIndexOf('.');
  var stem = dot < 0 ? path : path.substring(0, dot);
  if (stem.endsWith('l') || stem.endsWith('t')) {
    stem = stem.substring(0, stem.length - 1);
  }
  return stem;
}
