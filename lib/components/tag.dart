import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';

/// A small label on a surface block: a type over a cover, a season, a
/// studio or a genre at the top of the Detail page.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = Tokens.inkSoft});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.space2,
        vertical: Tokens.space1,
      ),
      color: Tokens.surface,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: AppText.caption(color).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
