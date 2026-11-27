import 'package:flutter/widgets.dart';

/// Text cut to [lines] lines with an ellipsis, always as tall as that many
/// lines at any text size, so what sits under it never moves. [over] stands
/// in for the text, such as a skeleton while it loads.
class HeldLines extends StatelessWidget {
  const HeldLines(
    this.text, {
    super.key,
    required this.style,
    required this.lines,
    this.over,
  });

  final String text;
  final TextStyle style;
  final int lines;
  final Widget? over;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // empty lines hold the room
          ExcludeSemantics(
            child: Text('\n' * (lines - 1), maxLines: lines, style: style),
          ),
          over ??
              Text(
                text,
                maxLines: lines,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
        ],
      ),
    );
  }
}
