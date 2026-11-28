import 'package:flutter/widgets.dart';

/// The size [text] takes in [style] at [textScaler], laid out in [maxWidth].
/// [cut] is true when it runs past [maxLines].
({double width, double height, bool cut}) measureText(
  String text,
  TextStyle style, {
  required TextScaler textScaler,
  int? maxLines = 1,
  double maxWidth = double.infinity,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: maxWidth);
  final size = (
    width: painter.width,
    height: painter.height,
    cut: painter.didExceedMaxLines,
  );
  painter.dispose();
  return size;
}
