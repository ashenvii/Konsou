import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';

class KeyCaps extends StatelessWidget {
  const KeyCaps(this.keys, {super.key});

  final String keys;

  @override
  Widget build(BuildContext context) {
    // a lone "+" is the key itself, not a separator
    final parts = keys == '+' ? const ['+'] : keys.split('+');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, part) in parts.indexed) ...[
          if (index > 0) const SizedBox(width: Tokens.space1),
          _KeyCap(part),
        ],
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Tokens.ground,
        border: Border.all(color: Tokens.inkMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.space1,
          vertical: Tokens.space1,
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AppText.caption(Tokens.inkSoft)
              .copyWith(fontSize: Tokens.text1),
        ),
      ),
    );
  }
}
