import 'dart:io';

import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'skeleton.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.width,
    this.file,
    this.loading = false,
  });

  final double width;
  final File? file;
  final bool loading;

  static double heightFor(double width) => width * 3 / 2;

  @override
  Widget build(BuildContext context) {
    final height = heightFor(width);
    final file = this.file;
    final blank = loading
        ? Skeleton(width: width, height: height)
        : ColoredBox(
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
        // the blank block while the file is decoded, so nothing flashes
        frameBuilder: (context, child, frame, sync) =>
            frame == null && !sync ? blank : child,
        errorBuilder: (context, error, stack) => blank,
      ),
    );
  }
}
