import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// A row's column: a value over its small label, at a fixed [width] so the
/// columns line up from row to row. With no [label] the value stands alone.
class ValueColumn extends StatelessWidget {
  const ValueColumn({
    super.key,
    required this.width,
    required this.value,
    this.label,
  });

  final double width;
  final Widget value;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          value,
          if (label != null) ...[const SizedBox(height: Tokens.space1), label],
        ],
      ),
    );
  }
}
