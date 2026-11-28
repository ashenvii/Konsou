import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import 'measure_text.dart';
import 'one_line_text.dart';

/// A label that gets bold when [bold] is true without changing its width. The
/// box is always as wide as the wider of the two (bold is another family, so
/// either can be wider), so a row of tabs does not shift when the selection
/// moves. In a space too small for it, it shrinks and ends in an
/// ellipsis (put it in a Flexible inside a Row).
class WeightText extends StatelessWidget {
  const WeightText(
    this.text, {
    super.key,
    required this.color,
    required this.bold,
  });

  final String text;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    double measure(bool asBold) => measureText(
      text,
      AppText.label(color, bold: asBold),
      textScaler: MediaQuery.textScalerOf(context),
    ).width;

    final regular = measure(false);
    final heavy = measure(true);
    final width = regular > heavy ? regular : heavy;
    return SizedBox(
      width: width,
      child: Center(
        widthFactor: 1,
        child: OneLineText(text, style: AppText.label(color, bold: bold)),
      ),
    );
  }
}
