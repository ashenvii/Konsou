import 'package:flutter/widgets.dart';

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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space1),
              child: Text(
                '+',
                style: TextStyle(
                  fontFamily: Tokens.mono,
                  fontSize: Tokens.text1,
                  height: 1,
                  color: Tokens.inkMuted,
                ),
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
      color: Tokens.keySlab,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Tokens.keyDepth),
        child: ColoredBox(
          color: Tokens.keyFace,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.keyPadX,
              vertical: Tokens.keyPadY,
            ),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: Tokens.mono,
                fontWeight: FontWeight.w700,
                fontSize: Tokens.text1,
                height: 1,
                color: Tokens.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
