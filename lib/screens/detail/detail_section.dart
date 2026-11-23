import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';

/// One part of the Detail page under its own heading: the name large, how
/// many things it holds beside it, a quiet note at the right, and a faint
/// rule under them. Parts sit well apart, so each reads as its own place.
class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.aside,
    this.rule = Tokens.surface,
    this.last = false,
  });

  final String title;
  final Widget child;

  /// "4 songs".
  final String? count;

  /// A note at the heading's right, such as where the data comes from.
  final Widget? aside;

  /// The rule under the heading; a part on a filled plate needs another.
  final Color rule;

  /// The page's last part, with no gap under it.
  final bool last;

  /// The space between one part and the next.
  static const gap = Tokens.space5 * 2 + Tokens.space2;

  @override
  Widget build(BuildContext context) {
    final count = this.count;
    final aside = this.aside;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: rule)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: Tokens.space3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: AppText.heading),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: Tokens.space3),
                    Text(count, style: AppText.caption(Tokens.inkMuted)),
                  ],
                  const SizedBox(width: Tokens.space4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: aside ?? const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Tokens.space4 + Tokens.space1),
          child,
        ],
      ),
    );
  }
}
