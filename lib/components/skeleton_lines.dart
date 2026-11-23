import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'skeleton.dart';

/// The stand-in for a title and the small line under it, each a share of
/// the width.
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({
    super.key,
    required this.title,
    required this.line,
    this.gap = Tokens.space2,
  });

  final double title;
  final double line;
  final double gap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FractionallySizedBox(
        widthFactor: title,
        child: const Skeleton(height: Tokens.text2),
      ),
      SizedBox(height: gap),
      FractionallySizedBox(
        widthFactor: line,
        child: const Skeleton(height: Tokens.text1),
      ),
    ],
  );
}
