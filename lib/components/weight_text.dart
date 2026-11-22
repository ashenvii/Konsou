import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';

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
    double measure(bool asBold) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: AppText.label(color, bold: asBold),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final regular = measure(false);
    final heavy = measure(true);
    final width = regular > heavy ? regular : heavy;
    return SizedBox(
      width: width,
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(color, bold: bold),
        ),
      ),
    );
  }
}
