import 'package:flutter/widgets.dart';

/// Text that stays on one line and ends in an ellipsis when it does not fit.
class OneLineText extends StatelessWidget {
  const OneLineText(this.text, {super.key, required this.style, this.align});

  final String text;
  final TextStyle style;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: style,
  );
}
