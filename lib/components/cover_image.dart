import 'dart:io';

import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// A cover, [width] wide and 2:3 tall. Until there is a [file] it is a blank
/// square on the surface color, so rows and cards keep their size.
class CoverImage extends StatelessWidget {
  const CoverImage({super.key, required this.width, this.file});

  final double width;
  final File? file;

  /// Covers are 2:3, as MAL draws them.
  static double heightFor(double width) => width * 3 / 2;

  @override
  Widget build(BuildContext context) {
    final height = heightFor(width);
    final file = this.file;
    final blank = ColoredBox(
      color: Tokens.surface,
      child: SizedBox(width: width, height: height),
    );
    if (file == null) return blank;
    return SizedBox(
      width: width,
      height: height,
      child: Image.file(
        file,
        fit: BoxFit.cover,
        // decoded at the size it is drawn, not the file's size
        cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => blank,
      ),
    );
  }
}
