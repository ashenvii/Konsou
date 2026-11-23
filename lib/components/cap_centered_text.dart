import 'package:flutter/widgets.dart';

import 'cap_centered.dart';
import 'one_line_text.dart';

/// One line of text with its capitals at the middle of the box around it.
class CapCenteredText extends StatelessWidget {
  const CapCenteredText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => CapCentered(
    style: style,
    child: OneLineText(text, style: style),
  );
}
