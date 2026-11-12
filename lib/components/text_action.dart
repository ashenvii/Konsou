import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'pressable.dart';

/// A button that is only an amber word, such as Undo on a toast. It sits on a
/// surface fill; a null [onPressed] disables it.
class TextAction extends StatelessWidget {
  const TextAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      builder: (context, state) => Container(
        height: Tokens.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AppText.label(
            onPressed == null ? Tokens.inkMuted : Tokens.amber,
            bold: true,
          ),
        ),
      ),
    );
  }
}
