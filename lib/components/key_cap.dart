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
          if (index > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tokens.space1),
              child: Text(
                '+',
                style: AppText.tally(Tokens.inkMuted, size: Tokens.text1),
              ),
            ),
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
    // the slab under the face is the key's side
    return ColoredBox(
      color: Tokens.keyCapSlab,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Tokens.keyDepth),
        child: ColoredBox(
          color: Tokens.keyCapFace,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.keyPadX,
              vertical: Tokens.keyPadY,
            ),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AppText.tally(Tokens.inkSoft, size: Tokens.text1),
            ),
          ),
        ),
      ),
    );
  }
}
