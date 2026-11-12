import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'hover_mark.dart';
import 'pressable.dart';

class TextAction extends StatelessWidget {
  const TextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.quiet = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      builder: (context, state) => HoverMark(
        on: state.hovered,
        child: Container(
          height: Tokens.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AppText.label(
              onPressed == null
                  ? Tokens.inkMuted
                  : (quiet ? Tokens.ink : Tokens.amber),
              bold: true,
            ),
          ),
        ),
      ),
    );
  }
}
