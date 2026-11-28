import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'skeleton.dart';

/// A loading bar as tall as text at [size], from the left: long by default,
/// [SkeletonLine.short] for a small line, [SkeletonLine.full] for a line of
/// a paragraph. These three are the only lengths.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.size = Tokens.text2}) : _share = 0.6;

  const SkeletonLine.short({super.key, this.size = Tokens.text2})
    : _share = 0.3;

  const SkeletonLine.full({super.key, this.size = Tokens.text2}) : _share = 1;

  final double size;
  final double _share;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: Alignment.centerLeft,
    widthFactor: _share,
    child: Skeleton(height: size),
  );
}

/// The stand-in for a title and the small line under it.
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({super.key, this.gap = Tokens.space2});

  final double gap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SkeletonLine(),
      SizedBox(height: gap),
      const SkeletonLine.short(size: Tokens.text1),
    ],
  );
}
