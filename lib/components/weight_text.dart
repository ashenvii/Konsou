import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';

/// A label that gets bold when [bold] is true without changing its width. The
/// box is always as wide as the bold text, so a row of tabs does not shift when
/// the selection moves.
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
    final painter = TextPainter(
      text: TextSpan(text: text, style: AppText.label(color, bold: true)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return SizedBox(
      width: width,
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: AppText.label(color, bold: bold),
        ),
      ),
    );
  }
}
