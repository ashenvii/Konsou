import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'hairline.dart';

/// The heading over a group of rows, with a hairline out to the edge and how
/// many rows the group holds when [count] is given.
class GroupHeading extends StatelessWidget {
  const GroupHeading(this.text, {super.key, this.count});

  final String text;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final style = AppText.caption(Tokens.inkMuted);
    return Row(
      children: [
        Text(text, style: style),
        if (count != null) ...[
          const SizedBox(width: Tokens.space2),
          Text('$count', style: style),
        ],
        const SizedBox(width: Tokens.space3),
        const Expanded(child: Hairline()),
      ],
    );
  }
}
