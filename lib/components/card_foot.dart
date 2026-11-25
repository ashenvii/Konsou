import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../library/entry_status.dart';
import 'count_style.dart';
import 'status_lamp.dart';
import 'status_mark.dart';

/// The strip under a card's cover, inside its well: the lamp, the status mark
/// on a tab that mixes statuses, the status word on hover, and the episode
/// count at the right. A title not on your list ([status] null) has only the
/// count. The count is never cut: where the room runs out the word goes
/// first, then the mark, then the lamp.
class CardFoot extends StatelessWidget {
  const CardFoot({
    super.key,
    required this.count,
    this.status,
    this.finished = true,
    this.showMark = false,
    this.showWord = false,
  });

  final String count;
  final EntryStatus? status;

  /// Off for a Completed franchise with a season left, so it does not light.
  final bool finished;
  final bool showMark;

  /// Hover or keyboard focus.
  final bool showWord;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    final countStyle = chooseCountStyle(status, size: Tokens.text1);
    final wordStyle = AppText.caption(Tokens.inkSoft);
    final scaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final direction = Directionality.of(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    return SizedBox(
      height: Tokens.cardFootHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.space1),
        child: LayoutBuilder(
          builder: (context, constraints) {
            var room = constraints.maxWidth - measure(count, countStyle);
            bool take(double width) {
              if (width + Tokens.space1 > room) return false;
              room -= width + Tokens.space1;
              return true;
            }

            final lamp = status != null && take(Tokens.lampSize);
            final mark = lamp && showMark && take(Tokens.iconSize);
            final word =
                lamp && showWord && take(measure(status.label, wordStyle));
            return Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lamp) StatusLamp(status, finished: finished),
                      if (mark) ...[
                        const SizedBox(width: Tokens.space1),
                        StatusMark(status, green: finished),
                      ],
                      if (word) ...[
                        const SizedBox(width: Tokens.space1),
                        Text(
                          status.label,
                          maxLines: 1,
                          softWrap: false,
                          style: wordStyle,
                        ),
                      ],
                    ],
                  ),
                ),
                // a count wider than the card at a very large text size
                // spills to the left rather than being cut
                Positioned.fill(
                  child: OverflowBox(
                    alignment: Alignment.centerRight,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    child: Text(
                      count,
                      maxLines: 1,
                      softWrap: false,
                      style: countStyle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
