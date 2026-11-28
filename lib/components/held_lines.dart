import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../library/row_labels.dart';
import 'skeleton_lines.dart';

/// Text cut to [lines] lines with an ellipsis, always as tall as that many
/// lines at any text size, so what sits under it never moves. While
/// [loading] it shows one bar per line, the last one shorter.
class HeldLines extends StatelessWidget {
  const HeldLines(
    this.text, {
    super.key,
    required this.style,
    required this.lines,
    this.loading = false,
  });

  final String text;
  final TextStyle style;
  final int lines;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? Tokens.text2;
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // empty lines hold the room
          ExcludeSemantics(
            child: Text('\n' * (lines - 1), maxLines: lines, style: style),
          ),
          // the bars share out the held room, so they never change its height
          if (loading)
            Positioned.fill(
              child: Semantics(
                label: loadingDetails,
                child: Column(
                  children: [
                    for (var i = 0; i < lines; i++)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: i == lines - 1
                              ? SkeletonLine(size: size)
                              : SkeletonLine.full(size: size),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
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
