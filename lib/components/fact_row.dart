import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';

/// A fact as a label beside its value, the value wrapping under itself, or
/// with [oneLine] kept to one line and cut with an ellipsis. A [child] stands
/// in for the value, such as a skeleton while it loads.
class FactRow extends StatelessWidget {
  const FactRow(
    this.label, {
    super.key,
    this.value = '',
    this.child,
    this.oneLine = false,
    this.labelWidth = defaultLabelWidth,
  });

  final String label;
  final String value;
  final Widget? child;
  final bool oneLine;
  final double labelWidth;

  static const defaultLabelWidth = Tokens.space5 * 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: oneLine ? 1 : null,
              overflow: oneLine ? TextOverflow.ellipsis : null,
              style: AppText.paragraph(Tokens.inkMuted),
            ),
          ),
          Expanded(
            child:
                child ??
                Text(
                  value,
                  maxLines: oneLine ? 1 : null,
                  overflow: oneLine ? TextOverflow.ellipsis : null,
                  style: AppText.paragraph(Tokens.inkSoft),
                ),
          ),
        ],
      ),
    );
  }
}
