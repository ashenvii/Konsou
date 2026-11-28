import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';

/// A line in place of what would be there: nothing found, nothing saved, no
/// connection. Its [action], such as Retry, goes under it.
class Message extends StatelessWidget {
  const Message(
    this.text, {
    super.key,
    this.action,
    this.padding = EdgeInsets.zero,
  });

  final String text;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppText.label(Tokens.inkSoft)),
          if (action != null) ...[
            const SizedBox(height: Tokens.space4),
            // only as wide as the action, so its hover stays on it
            IntrinsicWidth(child: action),
          ],
        ],
      ),
    );
  }
}
