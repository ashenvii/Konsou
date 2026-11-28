import 'package:flutter/widgets.dart';

import '../../components/skeleton_lines.dart';
import '../../design/tokens.dart';

/// The rows that hold the page picker's space while pages are looked up.
class PickerSkeleton extends StatelessWidget {
  const PickerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.all(Tokens.space3),
            child: SkeletonLines(),
          ),
      ],
    );
  }
}
